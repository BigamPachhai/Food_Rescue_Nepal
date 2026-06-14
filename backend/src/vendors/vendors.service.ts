import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateVendorDto } from './dto/update-vendor.dto';
import { VendorStatus } from '@prisma/client';

@Injectable()
export class VendorsService {
  constructor(private prisma: PrismaService) {}

  async findAll(lat?: number, lng?: number) {
    const vendors = await this.prisma.vendor.findMany({
      where: { status: VendorStatus.APPROVED },
      include: {
        user: {
          select: { name: true, email: true, avatarUrl: true },
        },
        _count: { select: { listings: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (lat != null && lng != null) {
      return vendors
        .map((v) => ({
          ...v,
          distance: this.haversine(lat, lng, v.lat, v.lng),
        }))
        .sort((a, b) => a.distance - b.distance);
    }

    return vendors;
  }

  async findOne(id: string) {
    const vendor = await this.prisma.vendor.findUnique({
      where: { id },
      include: {
        user: { select: { name: true, email: true, avatarUrl: true } },
        listings: {
          where: { isActive: true },
          orderBy: { createdAt: 'desc' },
        },
        reviews: {
          include: {
            customer: { select: { name: true, avatarUrl: true } },
          },
          orderBy: { createdAt: 'desc' },
          take: 10,
        },
      },
    });

    if (!vendor) {
      throw new NotFoundException('Vendor not found');
    }

    return vendor;
  }

  async updateProfile(userId: string, dto: UpdateVendorDto) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) {
      throw new NotFoundException('Vendor profile not found');
    }

    return this.prisma.vendor.update({
      where: { userId },
      data: {
        ...(dto.businessName && { businessName: dto.businessName }),
        ...(dto.businessType && { businessType: dto.businessType }),
        ...(dto.address && { address: dto.address }),
        ...(dto.lat != null && { lat: dto.lat }),
        ...(dto.lng != null && { lng: dto.lng }),
        ...(dto.description !== undefined && { description: dto.description }),
      },
    });
  }

  async updateLogo(userId: string, logoUrl: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) {
      throw new NotFoundException('Vendor profile not found');
    }
    return this.prisma.vendor.update({
      where: { userId },
      data: { logoUrl },
    });
  }

  async getStats(userId: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) throw new NotFoundException('Vendor not found');

    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const [
      todayOrders,
      pendingOrders,
      activeListings,
      todayRevenue,
      totalReservations,
      completedPickups,
      totalRevenue,
      listings,
    ] = await Promise.all([
      this.prisma.order.count({
        where: { vendorId: vendor.id, createdAt: { gte: todayStart } },
      }),
      this.prisma.order.count({
        where: { vendorId: vendor.id, status: 'PENDING' },
      }),
      this.prisma.listing.count({
        where: { vendorId: vendor.id, isActive: true },
      }),
      this.prisma.order.aggregate({
        where: {
          vendorId: vendor.id,
          status: { in: ['PICKED_UP', 'READY', 'CONFIRMED'] },
          createdAt: { gte: todayStart },
        },
        _sum: { totalAmount: true },
      }),
      this.prisma.order.count({
        where: { vendorId: vendor.id },
      }),
      this.prisma.order.count({
        where: { vendorId: vendor.id, status: 'PICKED_UP' },
      }),
      this.prisma.order.aggregate({
        where: { vendorId: vendor.id, status: 'PICKED_UP' },
        _sum: { totalAmount: true },
      }),
      this.prisma.listing.findMany({
        where: { vendorId: vendor.id },
        select: {
          id: true,
          name: true,
          availableQty: true,
          originalPrice: true,
          discountedPrice: true,
          isActive: true,
          _count: { select: { orders: true } },
          orders: {
            where: { status: 'PICKED_UP' },
            select: { totalAmount: true, quantity: true },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: 10,
      }),
    ]);

    const listingPerformance = listings.map((l) => ({
      id: l.id,
      name: l.name,
      availableQty: l.availableQty,
      isActive: l.isActive,
      totalOrders: l._count.orders,
      completedOrders: l.orders.length,
      revenuePaisa: l.orders.reduce((sum, o) => sum + o.totalAmount, 0),
      quantitySold: l.orders.reduce((sum, o) => sum + o.quantity, 0),
    }));

    return {
      todayOrders,
      todayEarned: todayRevenue._sum?.totalAmount ?? 0,
      foodSavedKg: todayOrders * 0.5,
      pendingOrders,
      activeListings,
      totalReservations,
      completedPickups,
      totalFoodSavedKg: completedPickups * 0.5,
      totalRevenuePaisa: totalRevenue._sum?.totalAmount ?? 0,
      listingPerformance,
    };
  }

  async getVendorByUserId(userId: string) {
    return this.prisma.vendor.findUnique({ where: { userId } });
  }

  private haversine(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371; // Earth radius in km
    const dLat = this.toRad(lat2 - lat1);
    const dLng = this.toRad(lng2 - lng1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRad(lat1)) *
        Math.cos(this.toRad(lat2)) *
        Math.sin(dLng / 2) *
        Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private toRad(deg: number): number {
    return deg * (Math.PI / 180);
  }
}
