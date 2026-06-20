import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { AnnouncementTarget } from '@prisma/client';
import { IsString, IsOptional, IsIn } from 'class-validator';

export class CreateAnnouncementDto {
  @IsString()
  title: string;

  @IsString()
  body: string;

  @IsOptional()
  @IsIn(['ALL', 'CUSTOMERS', 'VENDORS', 'ADMINS'])
  target?: AnnouncementTarget;

  @IsOptional()
  @IsString()
  imageUrl?: string;
}

@Injectable()
export class AnnouncementsService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  async create(authorId: string, dto: CreateAnnouncementDto) {
    const announcement = await this.prisma.announcement.create({
      data: {
        authorId,
        title: dto.title,
        body: dto.body,
        target: dto.target ?? AnnouncementTarget.ALL,
        imageUrl: dto.imageUrl,
      },
    });

    // Push to targeted users
    setImmediate(async () => {
      try {
        const roleMap: Record<AnnouncementTarget, string | null> = {
          ALL: null,
          CUSTOMERS: 'CUSTOMER',
          VENDORS: 'VENDOR',
          ADMINS: 'ADMIN',
        };
        const role = roleMap[announcement.target];
        const users = await this.prisma.user.findMany({
          where: { isActive: true, fcmToken: { not: null }, ...(role ? { role: role as any } : {}) },
          select: { id: true, fcmToken: true },
        });

        for (const user of users) {
          await this.notificationsService.send({
            userId: user.id,
            title: dto.title,
            body: dto.body,
            type: 'ANNOUNCEMENT',
            data: { announcementId: announcement.id },
            fcmToken: user.fcmToken!,
          });
        }
      } catch (_) {}
    });

    return announcement;
  }

  async getActive(userRole?: string) {
    const target: AnnouncementTarget[] = [AnnouncementTarget.ALL];
    if (userRole === 'CUSTOMER') target.push(AnnouncementTarget.CUSTOMERS);
    if (userRole === 'VENDOR') target.push(AnnouncementTarget.VENDORS);
    if (userRole === 'ADMIN') target.push(AnnouncementTarget.ADMINS);

    return this.prisma.announcement.findMany({
      where: { isActive: true, target: { in: target } },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });
  }

  async getAll(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      this.prisma.announcement.findMany({
        skip, take: limit,
        include: { author: { select: { name: true } } },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.announcement.count(),
    ]);
    return { items, total, page, limit };
  }

  async deactivate(id: string) {
    const item = await this.prisma.announcement.findUnique({ where: { id } });
    if (!item) throw new NotFoundException('Announcement not found');
    return this.prisma.announcement.update({ where: { id }, data: { isActive: false } });
  }
}
