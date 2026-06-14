import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class FavoritesService {
  constructor(private prisma: PrismaService) {}

  async toggle(userId: string, listingId: string) {
    const listing = await this.prisma.listing.findUnique({ where: { id: listingId } });
    if (!listing) throw new NotFoundException('Listing not found');

    const existing = await this.prisma.favorite.findUnique({
      where: { userId_listingId: { userId, listingId } },
    });

    if (existing) {
      await this.prisma.favorite.delete({
        where: { userId_listingId: { userId, listingId } },
      });
      return { favorited: false, listingId };
    } else {
      await this.prisma.favorite.create({
        data: { userId, listingId },
      });
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
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    return favorites;
  }
}
