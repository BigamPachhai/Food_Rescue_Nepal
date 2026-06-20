import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { IsString } from 'class-validator';

export class SendMessageDto {
  @IsString()
  body: string;
}

@Injectable()
export class ChatService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  async sendMessage(orderId: string, senderId: string, body: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        customer: { select: { id: true, name: true, fcmToken: true } },
        vendor: { include: { user: { select: { id: true, name: true, fcmToken: true } } } },
      },
    });

    if (!order) throw new NotFoundException('Order not found');

    const isCustomer = order.customerId === senderId;
    const isVendor = order.vendor.userId === senderId;
    if (!isCustomer && !isVendor) throw new ForbiddenException('Not a participant of this order');

    const message = await this.prisma.message.create({
      data: { orderId, senderId, body },
      include: { sender: { select: { id: true, name: true, avatarUrl: true } } },
    });

    // Push notification to the other party
    const recipientId = isCustomer ? order.vendor.user.id : order.customer.id;
    const recipientToken = isCustomer ? order.vendor.user.fcmToken : order.customer.fcmToken;
    const senderName = isCustomer ? order.customer.name : order.vendor.user.name;

    setImmediate(async () => {
      try {
        await this.notificationsService.send({
          userId: recipientId,
          title: `💬 ${senderName}`,
          body: body.length > 80 ? `${body.slice(0, 80)}…` : body,
          type: 'NEW_MESSAGE',
          data: { orderId },
          fcmToken: recipientToken || undefined,
        });
      } catch (_) {}
    });

    return message;
  }

  async getMessages(orderId: string, userId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { vendor: { select: { userId: true } } },
    });
    if (!order) throw new NotFoundException('Order not found');

    const isCustomer = order.customerId === userId;
    const isVendor = order.vendor.userId === userId;
    if (!isCustomer && !isVendor) throw new ForbiddenException('Access denied');

    // Mark unread as read
    await this.prisma.message.updateMany({
      where: { orderId, senderId: { not: userId }, isRead: false },
      data: { isRead: true },
    });

    return this.prisma.message.findMany({
      where: { orderId },
      include: { sender: { select: { id: true, name: true, avatarUrl: true } } },
      orderBy: { createdAt: 'asc' },
    });
  }

  async getUnreadCount(userId: string) {
    const orders = await this.prisma.order.findMany({
      where: {
        OR: [
          { customerId: userId },
          { vendor: { userId } },
        ],
      },
      select: { id: true },
    });
    const orderIds = orders.map((o) => o.id);
    const count = await this.prisma.message.count({
      where: { orderId: { in: orderIds }, senderId: { not: userId }, isRead: false },
    });
    return { unreadCount: count };
  }
}
