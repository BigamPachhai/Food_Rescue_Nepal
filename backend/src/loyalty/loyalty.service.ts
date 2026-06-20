import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

const POINTS_PER_ORDER = 10; // points per Rs.100 spent

@Injectable()
export class LoyaltyService {
  constructor(private prisma: PrismaService) {}

  async getOrCreateAccount(userId: string) {
    let account = await this.prisma.loyaltyAccount.findUnique({ where: { userId } });
    if (!account) {
      account = await this.prisma.loyaltyAccount.create({ data: { userId } });
    }
    return account;
  }

  async getBalance(userId: string) {
    const account = await this.getOrCreateAccount(userId);
    const transactions = await this.prisma.loyaltyTransaction.findMany({
      where: { accountId: account.id },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    return { balance: account.balance, totalEarned: account.totalEarned, totalSpent: account.totalSpent, transactions };
  }

  async earnOnOrder(userId: string, orderId: string, orderAmount: number) {
    const account = await this.getOrCreateAccount(userId);
    const points = Math.floor((orderAmount / 100) * POINTS_PER_ORDER);
    if (points < 1) return;

    await this.prisma.$transaction([
      this.prisma.loyaltyAccount.update({
        where: { id: account.id },
        data: { balance: { increment: points }, totalEarned: { increment: points } },
      }),
      this.prisma.loyaltyTransaction.create({
        data: {
          accountId: account.id,
          type: 'EARN',
          points,
          description: `Earned for completing order`,
          orderId,
        },
      }),
    ]);

    return points;
  }

  async redeemPoints(userId: string, points: number, orderId: string) {
    const account = await this.getOrCreateAccount(userId);
    if (account.balance < points) {
      throw new BadRequestException(`Insufficient points. Balance: ${account.balance}`);
    }

    const discountNpr = Math.floor(points / 2); // 2 points = Rs.1

    await this.prisma.$transaction([
      this.prisma.loyaltyAccount.update({
        where: { id: account.id },
        data: { balance: { decrement: points }, totalSpent: { increment: points } },
      }),
      this.prisma.loyaltyTransaction.create({
        data: {
          accountId: account.id,
          type: 'REDEEM',
          points: -points,
          description: `Redeemed for discount on order`,
          orderId,
        },
      }),
    ]);

    return { pointsRedeemed: points, discountNpr };
  }

  async awardReferralBonus(userId: string, referrerId: string) {
    const [account, referrerAccount] = await Promise.all([
      this.getOrCreateAccount(userId),
      this.getOrCreateAccount(referrerId),
    ]);

    await this.prisma.$transaction([
      this.prisma.loyaltyAccount.update({
        where: { id: account.id },
        data: { balance: { increment: 50 }, totalEarned: { increment: 50 } },
      }),
      this.prisma.loyaltyTransaction.create({
        data: { accountId: account.id, type: 'REFERRAL_BONUS', points: 50, description: 'Signed up via referral link' },
      }),
      this.prisma.loyaltyAccount.update({
        where: { id: referrerAccount.id },
        data: { balance: { increment: 100 }, totalEarned: { increment: 100 } },
      }),
      this.prisma.loyaltyTransaction.create({
        data: { accountId: referrerAccount.id, type: 'REFERRAL_BONUS', points: 100, description: 'Friend joined using your referral code' },
      }),
    ]);
  }
}
