import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as admin from 'firebase-admin';

export interface SendNotificationPayload {
  userId: string;
  title: string;
  body: string;
  type: string;
  data?: Record<string, any>;
  fcmToken?: string;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private firebaseInitialized = false;

  constructor(private prisma: PrismaService) {}

  setFirebaseInitialized(value: boolean) {
    this.firebaseInitialized = value;
  }

  async send(payload: SendNotificationPayload) {
    // 1. Store notification in DB
    let notification: any;
    try {
      notification = await this.prisma.notification.create({
        data: {
          userId: payload.userId,
          title: payload.title,
          body: payload.body,
          type: payload.type,
          data: payload.data ?? undefined,
        },
      });
    } catch (err) {
      this.logger.error('Failed to save notification to DB', err);
      return null;
    }

    // 2. Send FCM push if token available
    if (payload.fcmToken && this.firebaseInitialized) {
      await this.sendFcm(payload.fcmToken, payload.title, payload.body, payload.data);
    } else if (payload.userId && this.firebaseInitialized) {
      // Try to get fcmToken from DB
      try {
        const user = await this.prisma.user.findUnique({
          where: { id: payload.userId },
          select: { fcmToken: true },
        });
        if (user?.fcmToken) {
          await this.sendFcm(user.fcmToken, payload.title, payload.body, payload.data);
        }
      } catch (err) {
        this.logger.warn('Could not fetch FCM token for user', err);
      }
    }

    return notification;
  }

  private async sendFcm(
    token: string,
    title: string,
    body: string,
    data?: Record<string, any>,
  ) {
    try {
      const message: admin.messaging.Message = {
        token,
        notification: { title, body },
        data: data
          ? Object.fromEntries(
              Object.entries(data).map(([k, v]) => [k, String(v)]),
            )
          : undefined,
        android: {
          priority: 'high',
          notification: { sound: 'default' },
        },
        apns: {
          payload: { aps: { sound: 'default' } },
        },
      };
      await admin.messaging().send(message);
      this.logger.debug(`FCM sent: ${title}`);
    } catch (err) {
      this.logger.warn(`FCM send failed (non-fatal): ${(err as Error).message}`);
    }
  }

  async getNotifications(userId: string, page: number = 1, limit: number = 20) {
    const skip = (page - 1) * limit;
    const [notifications, total] = await Promise.all([
      this.prisma.notification.findMany({
        where: { userId },
        orderBy: [{ isRead: 'asc' }, { createdAt: 'desc' }],
        skip,
        take: limit,
      }),
      this.prisma.notification.count({ where: { userId } }),
    ]);
    return { notifications, total, page, limit };
  }

  async markRead(notificationId: string, userId: string) {
    const notification = await this.prisma.notification.findFirst({
      where: { id: notificationId, userId },
    });
    if (!notification) {
      return null;
    }
    return this.prisma.notification.update({
      where: { id: notificationId },
      data: { isRead: true },
    });
  }

  async markAllRead(userId: string) {
    const result = await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
    return { updated: result.count };
  }

  async getUnreadCount(userId: string) {
    const count = await this.prisma.notification.count({
      where: { userId, isRead: false },
    });
    return { count };
  }
}
