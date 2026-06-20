import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class FavoritesService {
  constructor(private prisma: PrismaService) {}

  // ── Listing favorites ──────────────────────────────────────────────────────

  async toggle(userId: string, listingId: string) {
    const listing = await this.prisma.listing.findUnique({ where: { id: listingId } });
    if (!listing) throw new NotFoundException('Listing not found');

    const existing = await this.prisma.favorite.findUnique({
      where: { userId_listingId: { userId, listingId } },
    });

    if (existing) {
      await this.prisma.favorite.deleteMany({
        where: { userId, listingId },
      });
      return { favorited: false, listingId };
    } else {
      await this.prisma.favorite.create({ data: { userId, listingId } });
      return { favorited: true, listingId };
    }
  }

  async getMyFavorites(userId: string) {
    const favorites = await this.prisma.favorite.findMany({
      where: { userId },
      include: {
        listing: {
          include: {
            vendor: {
              select: {
                id: true,
                businessName: true,
                address: true,
                logoUrl: true,
                avgRating: true,
                totalReviews: true,
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    return favorites.map((f) => f.listing);
  }

  // ── Vendor favorites ────────────────────────────────────────────────────────

  async toggleVendor(userId: string, vendorId: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { id: vendorId } });
    if (!vendor) throw new NotFoundException('Vendor not found');

    const existing = await this.prisma.vendorFavorite.findUnique({
      where: { userId_vendorId: { userId, vendorId } },
    });

    if (existing) {
      await this.prisma.vendorFavorite.deleteMany({
        where: { userId, vendorId },
      });
      return { favorited: false, vendorId };
    } else {
      await this.prisma.vendorFavorite.create({ data: { userId, vendorId } });
      return { favorited: true, vendorId };
    }
  }

  async getMyVendorFavorites(userId: string) {
    const favorites = await this.prisma.vendorFavorite.findMany({
      where: { userId },
      include: {
        vendor: {
          select: {
            id: true,
            userId: true,
            businessName: true,
            businessType: true,
            address: true,
            logoUrl: true,
            avgRating: true,
            totalReviews: true,
            status: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    return favorites.map((f) => f.vendor);
  }
}
