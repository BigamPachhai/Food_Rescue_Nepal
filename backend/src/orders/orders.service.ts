import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { OrderStatus } from '@prisma/client';
import { IsArray, IsString } from 'class-validator';

export class BulkAcceptDto {
  @IsArray()
  @IsString({ each: true })
  orderIds: string[];
}

@Injectable()
export class OrdersService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  private generatePickupCode(): string {
    return Math.random().toString(36).substring(2, 8).toUpperCase();
  }

  async create(customerId: string, dto: CreateOrderDto) {
    return this.prisma.$transaction(async (tx) => {
      const listing = await tx.listing.findUnique({
        where: { id: dto.listingId },
        include: {
          vendor: {
            include: { user: { select: { id: true, name: true, fcmToken: true } } },
          },
        },
      });

      if (!listing || !listing.isActive) {
        throw new NotFoundException('Listing not found or inactive');
      }

      if (dto.quantity < 1) {
        throw new BadRequestException('Quantity must be at least 1');
      }

      if (listing.availableQty < dto.quantity) {
        throw new BadRequestException(
          `Not enough quantity. Available: ${listing.availableQty}`,
        );
      }

      // Atomic conditional decrement — prevents race condition on concurrent orders
      const decremented = await tx.listing.updateMany({
        where: { id: dto.listingId, availableQty: { gte: dto.quantity } },
        data: { availableQty: { decrement: dto.quantity } },
      });
      if (decremented.count === 0) {
        throw new BadRequestException('Item just sold out — please try again');
      }

      const customer = await tx.user.findUnique({
        where: { id: customerId },
        select: { id: true, name: true },
      });

      const order = await tx.order.create({
        data: {
          customerId,
          vendorId: listing.vendorId,
          listingId: dto.listingId,
          quantity: dto.quantity,
          totalAmount: listing.discountedPrice * dto.quantity,
          pickupCode: this.generatePickupCode(),
          notes: dto.notes,
        },
        include: {
          listing: true,
          vendor: true,
          customer: { select: { id: true, name: true, email: true } },
        },
      });

      // Notify vendor
      setImmediate(async () => {
        try {
          await this.notificationsService.send({
            userId: listing.vendor.user.id,
            title: 'New Order! 🎉',
            body: `${customer!.name} ordered ${listing.name} × ${dto.quantity}`,
            type: 'NEW_ORDER',
            data: { orderId: order.id },
            fcmToken: listing.vendor.user.fcmToken || undefined,
          });
        } catch (_) {}
      });

      return order;
    });
  }

  async getCustomerOrders(customerId: string, page: number = 1, limit: number = 20) {
    const skip = (page - 1) * limit;
    const [orders, total] = await Promise.all([
      this.prisma.order.findMany({
        where: { customerId },
        include: {
          listing: {
            select: {
              id: true,
              name: true,
              imageUrls: true,
              originalPrice: true,
              discountedPrice: true,
              pickupStart: true,
              pickupEnd: true,
            },
          },
          vendor: { select: { businessName: true, address: true, logoUrl: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.order.count({ where: { customerId } }),
    ]);
    return { orders, total, page, limit };
  }

  async getVendorOrders(userId: string, page: number = 1, limit: number = 20) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) throw new ForbiddenException('Vendor profile not found');

    const skip = (page - 1) * limit;
    const [orders, total] = await Promise.all([
      this.prisma.order.findMany({
        where: { vendorId: vendor.id },
        include: {
          listing: {
            select: {
              id: true,
              name: true,
              imageUrls: true,
              pickupStart: true,
              pickupEnd: true,
              discountedPrice: true,
            },
          },
          customer: { select: { name: true, email: true, phone: true, avatarUrl: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.order.count({ where: { vendorId: vendor.id } }),
    ]);
    return { orders, total, page, limit };
  }

  async findOne(orderId: string, userId: string, userRole: string, vendorId?: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        listing: true,
        vendor: { include: { user: { select: { id: true } } } },
        customer: { select: { id: true, name: true, email: true, phone: true } },
        review: true,
      },
    });

    if (!order) throw new NotFoundException('Order not found');

    if (userRole === 'ADMIN') return order;
    if (order.customerId === userId) return order;
    if (order.vendor.userId === userId) return order;

    throw new ForbiddenException('Access denied');
  }

  async accept(orderId: string, userId: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) throw new ForbiddenException('Vendor profile not found');

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        listing: { select: { name: true, pickupStart: true, pickupEnd: true } },
        customer: { select: { id: true, name: true, fcmToken: true } },
      },
    });

    if (!order) throw new NotFoundException('Order not found');
    if (order.vendorId !== vendor.id) throw new ForbiddenException('Not your order');
    if (order.status !== OrderStatus.PENDING) {
      throw new BadRequestException('Order is not in PENDING status');
    }

    const updated = await this.prisma.order.update({
      where: { id: orderId },
      data: { status: OrderStatus.ACCEPTED, acceptedAt: new Date() },
    });

    setImmediate(async () => {
      try {
        const pickupStart = order.listing.pickupStart.toLocaleTimeString();
        const pickupEnd = order.listing.pickupEnd.toLocaleTimeString();
        await this.notificationsService.send({
          userId: order.customer.id,
          title: 'Order Accepted ✅',
          body: `Pick up your ${order.listing.name} between ${pickupStart} and ${pickupEnd}`,
          type: 'ORDER_ACCEPTED',
          data: { orderId },
          fcmToken: order.customer.fcmToken || undefined,
        });
      } catch (_) {}
    });

    return updated;
  }

  async markReady(orderId: string, userId: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) throw new ForbiddenException('Vendor profile not found');

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        listing: { select: { name: true } },
        customer: { select: { id: true, fcmToken: true } },
      },
    });

    if (!order) throw new NotFoundException('Order not found');
    if (order.vendorId !== vendor.id) throw new ForbiddenException('Not your order');
    if (order.status !== OrderStatus.ACCEPTED) {
      throw new BadRequestException('Order is not in ACCEPTED status');
    }

    const updated = await this.prisma.order.update({
      where: { id: orderId },
      data: { status: OrderStatus.READY, readyAt: new Date() },
    });

    setImmediate(async () => {
      try {
        await this.notificationsService.send({
          userId: order.customer.id,
          title: 'Ready for Pickup! 🟢',
          body: `${order.listing.name} is ready. Go pick it up!`,
          type: 'ORDER_READY',
          data: { orderId },
          fcmToken: order.customer.fcmToken || undefined,
        });
      } catch (_) {}
    });

    return updated;
  }

  async pickup(orderId: string, userId: string, pickupCode: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) throw new ForbiddenException('Vendor profile not found');

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        listing: { select: { name: true } },
        customer: { select: { id: true, fcmToken: true } },
      },
    });

    if (!order) throw new NotFoundException('Order not found');
    if (order.vendorId !== vendor.id) throw new ForbiddenException('Not your order');
    if (order.status !== OrderStatus.READY) {
      throw new BadRequestException('Order is not in READY status');
    }

    if (order.pickupCode !== pickupCode) {
      throw new BadRequestException('Invalid pickup code');
    }

    const updated = await this.prisma.order.update({
      where: { id: orderId },
      data: { status: OrderStatus.COMPLETED, completedAt: new Date() },
    });

    setImmediate(async () => {
      try {
        await this.notificationsService.send({
          userId: order.customer.id,
          title: 'Enjoy your meal! 🌿',
          body: 'Thanks for rescuing food with us.',
          type: 'ORDER_PICKED_UP',
          data: { orderId },
          fcmToken: order.customer.fcmToken || undefined,
        });
      } catch (_) {}
    });

    return updated;
  }

  async reject(orderId: string, userId: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) throw new ForbiddenException('Vendor profile not found');

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        listing: { select: { name: true } },
        customer: { select: { id: true, fcmToken: true } },
      },
    });

    if (!order) throw new NotFoundException('Order not found');
    if (order.vendorId !== vendor.id) throw new ForbiddenException('Not your order');
    if (order.status !== OrderStatus.PENDING) {
      throw new BadRequestException('Only PENDING reservations can be rejected');
    }

    const [updated] = await this.prisma.$transaction([
      this.prisma.order.update({
        where: { id: orderId },
        data: { status: OrderStatus.REJECTED },
      }),
      this.prisma.listing.update({
        where: { id: order.listingId },
        data: { availableQty: { increment: order.quantity } },
      }),
    ]);

    setImmediate(async () => {
      try {
        await this.notificationsService.send({
          userId: order.customer.id,
          title: 'Reservation Rejected',
          body: `Your reservation for ${order.listing.name} was rejected by the vendor.`,
          type: 'ORDER_REJECTED',
          data: { orderId },
          fcmToken: order.customer.fcmToken || undefined,
        });
      } catch (_) {}
    });

    return updated;
  }

  async expire(orderId: string, userId: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) throw new ForbiddenException('Vendor profile not found');

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        listing: { select: { name: true } },
        customer: { select: { id: true, fcmToken: true } },
      },
    });

    if (!order) throw new NotFoundException('Order not found');
    if (order.vendorId !== vendor.id) throw new ForbiddenException('Not your order');
    if (order.status !== OrderStatus.READY && order.status !== OrderStatus.ACCEPTED) {
      throw new BadRequestException('Only ACCEPTED or READY reservations can be marked as expired');
    }

    const [updated] = await this.prisma.$transaction([
      this.prisma.order.update({
        where: { id: orderId },
        data: { status: OrderStatus.EXPIRED },
      }),
      this.prisma.listing.update({
        where: { id: order.listingId },
        data: { availableQty: { increment: order.quantity } },
      }),
    ]);

    setImmediate(async () => {
      try {
        await this.notificationsService.send({
          userId: order.customer.id,
          title: 'Reservation Expired',
          body: `Your reservation for ${order.listing.name} has expired. The food could not be rescued.`,
          type: 'ORDER_EXPIRED',
          data: { orderId },
          fcmToken: order.customer.fcmToken || undefined,
        });
      } catch (_) {}
    });

    return updated;
  }

  async bulkAccept(userId: string, dto: BulkAcceptDto) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) throw new ForbiddenException('Vendor profile not found');

    const results: { id: string; success: boolean; error?: string }[] = [];
    for (const orderId of dto.orderIds) {
      try {
        await this.accept(orderId, userId);
        results.push({ id: orderId, success: true });
      } catch (e: any) {
        results.push({ id: orderId, success: false, error: e.message });
      }
    }
    return results;
  }

  private async updateCustomerReliability(customerId: string) {
    const [total, completed] = await Promise.all([
      this.prisma.order.count({ where: { customerId, status: { in: ['COMPLETED', 'CANCELLED', 'EXPIRED'] } } }),
      this.prisma.order.count({ where: { customerId, status: 'COMPLETED' } }),
    ]);
    const score = total > 0 ? Math.round((completed / total) * 100) : 100;
    await this.prisma.user.update({
      where: { id: customerId },
      data: { totalOrders: total, completedOrders: completed, reliabilityScore: score },
    });
  }

  async cancel(orderId: string, customerId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        listing: { select: { name: true } },
        vendor: {
          include: { user: { select: { id: true, fcmToken: true } } },
        },
        customer: { select: { name: true } },
      },
    });

    if (!order) throw new NotFoundException('Order not found');
    if (order.customerId !== customerId) throw new ForbiddenException('Not your order');
    if (order.status !== OrderStatus.PENDING) {
      throw new BadRequestException('Only PENDING orders can be cancelled');
    }

    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);
    if (order.createdAt < tenMinutesAgo) {
      throw new BadRequestException('Cannot cancel order after 10 minutes');
    }

    const [updated] = await this.prisma.$transaction([
      this.prisma.order.update({
        where: { id: orderId },
        data: { status: OrderStatus.CANCELLED },
      }),
      this.prisma.listing.update({
        where: { id: order.listingId },
        data: { availableQty: { increment: order.quantity } },
      }),
    ]);

    setImmediate(async () => {
      try {
        await this.notificationsService.send({
          userId: order.vendor.user.id,
          title: 'Order Cancelled',
          body: `${order.customer.name} cancelled their order for ${order.listing.name}`,
          type: 'ORDER_CANCELLED',
          data: { orderId },
          fcmToken: order.vendor.user.fcmToken || undefined,
        });
      } catch (_) {}
    });

    return updated;
  }
}
