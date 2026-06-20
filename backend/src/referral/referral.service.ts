import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { LoyaltyService } from '../loyalty/loyalty.service';

function generateCode(name: string): string {
  const base = name.toUpperCase().replace(/[^A-Z]/g, '').slice(0, 5) || 'USER';
  const suffix = Math.random().toString(36).substring(2, 6).toUpperCase();
  return `${base}${suffix}`;
}

@Injectable()
export class ReferralService {
  constructor(
    private prisma: PrismaService,
    private loyaltyService: LoyaltyService,
  ) {}

  async getOrCreateCode(userId: string): Promise<string> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    if (user.referralCode) return user.referralCode;

    let code: string;
    let attempt = 0;
    do {
      code = generateCode(user.name);
      attempt++;
      const exists = await this.prisma.user.findUnique({ where: { referralCode: code } });
      if (!exists) break;
    } while (attempt < 10);

    await this.prisma.user.update({ where: { id: userId }, data: { referralCode: code } });
    return code;
  }

  async getReferralStats(userId: string) {
    const referrals = await this.prisma.user.findMany({
      where: { referredById: userId },
      select: { id: true, name: true, createdAt: true },
    });

    const rewards = await this.prisma.referralReward.findMany({
      where: { referrerId: userId },
      orderBy: { createdAt: 'desc' },
    });

    return {
      totalReferrals: referrals.length,
      totalPointsEarned: rewards.reduce((sum, r) => sum + r.pointsAwarded, 0),
      referrals: referrals.map((r) => ({ name: r.name, joinedAt: r.createdAt })),
    };
  }

  async applyReferralCode(newUserId: string, code: string) {
    const referrer = await this.prisma.user.findUnique({ where: { referralCode: code } });
    if (!referrer || referrer.id === newUserId) return;

    const user = await this.prisma.user.findUnique({ where: { id: newUserId } });
    if (user?.referredById) return; // already used a code

    await this.prisma.user.update({
      where: { id: newUserId },
      data: { referredById: referrer.id },
    });

    await Promise.all([
      this.loyaltyService.awardReferralBonus(newUserId, referrer.id),
      this.prisma.referralReward.create({
        data: { referrerId: referrer.id, referredUserId: newUserId, pointsAwarded: 100 },
      }),
    ]);
  }
}
