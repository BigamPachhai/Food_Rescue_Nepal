import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class WaitlistService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  async join(userId: string, listingId: string) {
    const listing = await this.prisma.listing.findUnique({ where: { id: listingId } });
    if (!listing) throw new NotFoundException('Listing not found');

    if (listing.availableQty > 0) {
      throw new BadRequestException('Listing still has availability — place an order instead');
    }

    const existing = await this.prisma.waitlistEntry.findUnique({
      where: { userId_listingId: { userId, listingId } },
    });
    if (existing) throw new BadRequestException('Already on waitlist');

    return this.prisma.waitlistEntry.create({ data: { userId, listingId } });
  }

  async leave(userId: string, listingId: string) {
    const entry = await this.prisma.waitlistEntry.findUnique({
      where: { userId_listingId: { userId, listingId } },
    });
    if (!entry) throw new NotFoundException('Not on waitlist');
    return this.prisma.waitlistEntry.delete({
      where: { userId_listingId: { userId, listingId } },
    });
  }

  async getMyWaitlist(userId: string) {
    return this.prisma.waitlistEntry.findMany({
      where: { userId },
      include: {
        listing: {
          select: { id: true, name: true, imageUrls: true, discountedPrice: true, availableQty: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getListingWaitlist(listingId: string) {
    return this.prisma.waitlistEntry.findMany({
      where: { listingId },
      include: { user: { select: { id: true, name: true, email: true } } },
      orderBy: { createdAt: 'asc' },
    });
  }

  async isOnWaitlist(userId: string, listingId: string) {
    const entry = await this.prisma.waitlistEntry.findUnique({
      where: { userId_listingId: { userId, listingId } },
    });
    return { onWaitlist: !!entry, position: entry ? await this._getPosition(userId, listingId) : null };
  }

  async notifyWaitlist(listingId: string) {
    const entries = await this.prisma.waitlistEntry.findMany({
      where: { listingId, notified: false },
      include: { user: { select: { id: true, name: true, fcmToken: true } }, listing: { select: { name: true } } },
      orderBy: { createdAt: 'asc' },
    });

    for (const entry of entries) {
      setImmediate(async () => {
        try {
          await this.notificationsService.send({
            userId: entry.user.id,
            title: '🍱 Back in Stock!',
            body: `${entry.listing.name} is available again. Grab it before it runs out!`,
            type: 'WAITLIST_AVAILABLE',
            data: { listingId },
            fcmToken: entry.user.fcmToken || undefined,
          });
          await this.prisma.waitlistEntry.update({
            where: { userId_listingId: { userId: entry.userId, listingId } },
            data: { notified: true },
          });
        } catch (_) {}
      });
    }
  }

  private async _getPosition(userId: string, listingId: string): Promise<number> {
    const entries = await this.prisma.waitlistEntry.findMany({
      where: { listingId },
      orderBy: { createdAt: 'asc' },
      select: { userId: true },
    });
    return entries.findIndex((e) => e.userId === userId) + 1;
  }
}
