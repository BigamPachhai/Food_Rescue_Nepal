import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class DataExportService {
  constructor(private prisma: PrismaService) {}

  async requestExport(userId: string) {
    // Check for recent pending request
    const recent = await this.prisma.dataExportRequest.findFirst({
      where: { userId, status: { in: ['PENDING', 'PROCESSING'] } },
      orderBy: { createdAt: 'desc' },
    });
    if (recent) return { message: 'Export already in progress', requestId: recent.id };

    const request = await this.prisma.dataExportRequest.create({
      data: { userId, status: 'PROCESSING' },
    });

    // Build export data async
    setImmediate(async () => {
      try {
        const exportData = await this.buildExport(userId);
        // In production, upload to cloud storage. Here we store as JSON directly.
        const jsonStr = JSON.stringify(exportData, null, 2);
        const dataUrl = `data:application/json;base64,${Buffer.from(jsonStr).toString('base64')}`;
        const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days
        await this.prisma.dataExportRequest.update({
          where: { id: request.id },
          data: { status: 'READY', downloadUrl: dataUrl, expiresAt },
        });
      } catch (_) {
        await this.prisma.dataExportRequest.update({
          where: { id: request.id },
          data: { status: 'FAILED' },
        }).catch(() => {});
      }
    });

    return { message: 'Export started', requestId: request.id };
  }

  async getStatus(userId: string, requestId: string) {
    const req = await this.prisma.dataExportRequest.findFirst({
      where: { id: requestId, userId },
    });
    if (!req) throw new NotFoundException('Export request not found');
    return req;
  }

  async getMyRequests(userId: string) {
    return this.prisma.dataExportRequest.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });
  }

  private async buildExport(userId: string) {
    const [user, orders, reviews, notifications, favorites] = await Promise.all([
      this.prisma.user.findUnique({
        where: { id: userId },
        select: { id: true, name: true, email: true, phone: true, role: true, createdAt: true },
      }),
      this.prisma.order.findMany({
        where: { customerId: userId },
        include: { listing: { select: { name: true } }, vendor: { select: { businessName: true } } },
      }),
      this.prisma.review.findMany({ where: { customerId: userId } }),
      this.prisma.notification.findMany({ where: { userId }, take: 100 }),
      this.prisma.favorite.findMany({ where: { userId }, include: { listing: { select: { name: true } } } }),
    ]);

    return { exportedAt: new Date().toISOString(), user, orders, reviews, notifications, favorites };
  }

  async deleteAccount(userId: string) {
    // Cascade deletes handle most relations
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        name: 'Deleted User',
        email: `deleted_${userId}@foodrescue.np`,
        phone: null,
        passwordHash: null,
        googleId: null,
        avatarUrl: null,
        fcmToken: null,
        isActive: false,
        deletedAt: new Date(),
      },
    });
    return { message: 'Account deleted successfully' };
  }
}
