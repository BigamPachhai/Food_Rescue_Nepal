import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { VendorStatus, OrderStatus } from '@prisma/client';

@Injectable()
export class AdminService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  async getStats() {
    const [totalUsers, totalVendors, pendingVendors, activeListings, orderAgg] =
      await Promise.all([
        this.prisma.user.count({ where: { deletedAt: null } }),
        this.prisma.vendor.count(),
        this.prisma.vendor.count({ where: { status: VendorStatus.PENDING } }),
        this.prisma.listing.count({ where: { isActive: true } }),
        this.prisma.order.aggregate({
          _count: { id: true },
          _sum: { totalAmount: true },
        }),
      ]);

    return {
      totalUsers,
      totalVendors,
      totalOrders: orderAgg._count.id,
      totalRevenue: orderAgg._sum.totalAmount || 0,
      pendingVendors,
      activeListings,
    };
  }

  async getUsers(page: number, limit: number, role?: string, isActive?: boolean, search?: string) {
    const skip = (page - 1) * limit;
    const where: any = {
      deletedAt: null,
      ...(role && { role: role as any }),
      ...(isActive !== undefined && { isActive }),
      ...(search && {
        OR: [
          { name: { contains: search, mode: 'insensitive' } },
          { email: { contains: search, mode: 'insensitive' } },
        ],
      }),
    };

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          role: true,
          isActive: true,
          createdAt: true,
          avatarUrl: true,
          vendor: { select: { id: true, businessName: true, status: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.user.count({ where }),
    ]);
    return { users, total, page, limit };
  }

  async getUserById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: {
        vendor: true,
        orders: { take: 5, orderBy: { createdAt: 'desc' } },
        reviews: { take: 5, orderBy: { createdAt: 'desc' } },
      },
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async toggleUserBan(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException('User not found');

    return this.prisma.user.update({
      where: { id },
      data: { isActive: !user.isActive },
      select: { id: true, name: true, email: true, isActive: true },
    });
  }

  async getVendors(page: number, limit: number, status?: VendorStatus, search?: string) {
    const skip = (page - 1) * limit;
    const where: any = {
      ...(status && { status }),
      ...(search && {
        OR: [
          { businessName: { contains: search, mode: 'insensitive' } },
          { address: { contains: search, mode: 'insensitive' } },
        ],
      }),
    };

    const [vendors, total] = await Promise.all([
      this.prisma.vendor.findMany({
        where,
        include: {
          user: { select: { name: true, email: true, phone: true, isActive: true } },
          _count: { select: { listings: true, orders: true, reviews: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.vendor.count({ where }),
    ]);
    return { vendors, total, page, limit };
  }

  async getVendorById(id: string) {
    const vendor = await this.prisma.vendor.findUnique({
      where: { id },
      include: {
        user: { select: { name: true, email: true, phone: true, isActive: true, fcmToken: true } },
        listings: { where: { isActive: true }, take: 10 },
        reviews: { take: 5, orderBy: { createdAt: 'desc' } },
        _count: { select: { listings: true, orders: true } },
      },
    });
    if (!vendor) throw new NotFoundException('Vendor not found');
    return vendor;
  }

  async approveVendor(id: string) {
    const vendor = await this.prisma.vendor.findUnique({
      where: { id },
      include: { user: { select: { id: true, fcmToken: true } } },
    });
    if (!vendor) throw new NotFoundException('Vendor not found');

    const updated = await this.prisma.vendor.update({
      where: { id },
      data: { status: VendorStatus.APPROVED },
    });

    setImmediate(async () => {
      try {
        await this.notificationsService.send({
          userId: vendor.user.id,
          title: "You're Approved! 🎉",
          body: 'Your business is live on Food Rescue Nepal!',
          type: 'VENDOR_APPROVED',
          data: { vendorId: id },
          fcmToken: vendor.user.fcmToken || undefined,
        });
      } catch (_) {}
    });

    return updated;
  }

  async suspendVendor(id: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { id } });
    if (!vendor) throw new NotFoundException('Vendor not found');

    const [updatedVendor] = await this.prisma.$transaction([
      this.prisma.vendor.update({
        where: { id },
        data: { status: VendorStatus.SUSPENDED },
      }),
      // Deactivate all active listings so customers can't place new orders
      this.prisma.listing.updateMany({
        where: { vendorId: id, isActive: true },
        data: { isActive: false },
      }),
    ]);

    return updatedVendor;
  }

  async rejectVendor(id: string) {
    const vendor = await this.prisma.vendor.findUnique({
      where: { id },
      include: { user: { select: { id: true, fcmToken: true } } },
    });
    if (!vendor) throw new NotFoundException('Vendor not found');

    const [updatedVendor] = await this.prisma.$transaction([
      this.prisma.vendor.update({
        where: { id },
        data: { status: VendorStatus.REJECTED },
      }),
      this.prisma.listing.updateMany({
        where: { vendorId: id, isActive: true },
        data: { isActive: false },
      }),
    ]);

    setImmediate(async () => {
      try {
        await this.notificationsService.send({
          userId: vendor.user.id,
          title: 'Application Not Approved',
          body: 'Your vendor application was not approved. Contact support for more information.',
          type: 'VENDOR_REJECTED',
          data: { vendorId: id },
          fcmToken: vendor.user.fcmToken || undefined,
        });
      } catch (_) {}
    });

    return updatedVendor;
  }

  async getListings(isActive?: boolean, vendorId?: string, category?: string) {
    const where: any = {
      ...(isActive !== undefined && { isActive }),
      ...(vendorId && { vendorId }),
      ...(category && { category: category as any }),
    };

    return this.prisma.listing.findMany({
      where,
      include: {
        vendor: { select: { businessName: true, status: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async deactivateListing(id: string) {
    const listing = await this.prisma.listing.findUnique({ where: { id } });
    if (!listing) throw new NotFoundException('Listing not found');

    return this.prisma.listing.update({
      where: { id },
      data: { isActive: false },
    });
  }

  async getOrders(
    page: number,
    limit: number,
    status?: OrderStatus,
    vendorId?: string,
    customerId?: string,
  ) {
    const skip = (page - 1) * limit;
    const where: any = {
      ...(status && { status }),
      ...(vendorId && { vendorId }),
      ...(customerId && { customerId }),
    };

    const [orders, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
        include: {
          listing: { select: { name: true } },
          customer: { select: { name: true, email: true } },
          vendor: { select: { businessName: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.order.count({ where }),
    ]);
    return { orders, total, page, limit };
  }

  async getOrderById(id: string) {
    const order = await this.prisma.order.findUnique({
      where: { id },
      include: {
        listing: true,
        customer: { select: { name: true, email: true, phone: true } },
        vendor: { select: { businessName: true, address: true } },
        review: true,
      },
    });
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  async toggleFeaturedListing(id: string) {
    const listing = await this.prisma.listing.findUnique({ where: { id } });
    if (!listing) throw new NotFoundException('Listing not found');
    return this.prisma.listing.update({
      where: { id },
      data: { isFeatured: !listing.isFeatured },
    });
  }

  async getPlatformInsights() {
    const now = new Date();
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    const [
      newUsers30d,
      newVendors30d,
      orders30d,
      revenue30d,
      topListings,
      disputeCount,
    ] = await Promise.all([
      this.prisma.user.count({ where: { createdAt: { gte: thirtyDaysAgo } } }),
      this.prisma.vendor.count({ where: { createdAt: { gte: thirtyDaysAgo } } }),
      this.prisma.order.count({ where: { createdAt: { gte: thirtyDaysAgo } } }),
      this.prisma.order.aggregate({
        where: { status: 'COMPLETED', completedAt: { gte: thirtyDaysAgo } },
        _sum: { totalAmount: true },
      }),
      this.prisma.listing.findMany({
        orderBy: { trendingScore: 'desc' },
        take: 10,
        include: { vendor: { select: { businessName: true } } },
      }),
      this.prisma.orderDispute.count({ where: { status: 'OPEN' } }),
    ]);

    return {
      last30Days: {
        newUsers: newUsers30d,
        newVendors: newVendors30d,
        orders: orders30d,
        revenue: revenue30d._sum.totalAmount ?? 0,
      },
      topTrendingListings: topListings,
      openDisputes: disputeCount,
    };
  }
}
