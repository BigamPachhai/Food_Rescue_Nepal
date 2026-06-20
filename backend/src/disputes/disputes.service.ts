import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { IsString, IsOptional } from 'class-validator';
import { DisputeStatus } from '@prisma/client';

export class CreateDisputeDto {
  @IsString()
  orderId: string;

  @IsString()
  reason: string;

  @IsOptional()
  @IsString()
  description?: string;
}

export class ResolveDisputeDto {
  @IsString()
  resolution: DisputeStatus;

  @IsOptional()
  @IsString()
  adminNote?: string;
}

@Injectable()
export class DisputesService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  async create(reporterId: string, dto: CreateDisputeDto) {
    const order = await this.prisma.order.findUnique({
      where: { id: dto.orderId },
      include: { customer: { select: { id: true } }, vendor: { select: { userId: true } } },
    });

    if (!order) throw new NotFoundException('Order not found');
    if (order.customerId !== reporterId && order.vendor.userId !== reporterId) {
      throw new ForbiddenException('Access denied');
    }

    const existing = await this.prisma.orderDispute.findUnique({ where: { orderId: dto.orderId } });
    if (existing) throw new BadRequestException('A dispute already exists for this order');

    return this.prisma.orderDispute.create({
      data: { orderId: dto.orderId, reporterId, reason: dto.reason, description: dto.description },
    });
  }

  async getMyDisputes(userId: string) {
    return this.prisma.orderDispute.findMany({
      where: { reporterId: userId },
      include: { order: { include: { listing: { select: { name: true } }, vendor: { select: { businessName: true } } } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getAll(page = 1, limit = 20, status?: DisputeStatus) {
    const skip = (page - 1) * limit;
    const where = status ? { status } : {};
    const [items, total] = await Promise.all([
      this.prisma.orderDispute.findMany({
        where,
        include: {
          reporter: { select: { id: true, name: true, email: true } },
          order: { include: { listing: { select: { name: true } }, vendor: { select: { businessName: true } } } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.orderDispute.count({ where }),
    ]);
    return { items, total, page, limit };
  }

  async resolve(adminId: string, disputeId: string, dto: ResolveDisputeDto) {
    const dispute = await this.prisma.orderDispute.findUnique({
      where: { id: disputeId },
      include: { reporter: { select: { id: true, fcmToken: true } } },
    });
    if (!dispute) throw new NotFoundException('Dispute not found');

    const updated = await this.prisma.orderDispute.update({
      where: { id: disputeId },
      data: { status: dto.resolution, adminNote: dto.adminNote, resolvedAt: new Date() },
    });

    setImmediate(async () => {
      try {
        await this.notificationsService.send({
          userId: dispute.reporter.id,
          title: 'Dispute Updated',
          body: `Your dispute has been ${dto.resolution.toLowerCase()}.`,
          type: 'DISPUTE_RESOLVED',
          data: { disputeId },
          fcmToken: dispute.reporter.fcmToken || undefined,
        });
      } catch (_) {}
    });

    return updated;
  }
}
