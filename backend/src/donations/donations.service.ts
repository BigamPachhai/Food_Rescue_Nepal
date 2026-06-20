import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { IsString, IsOptional, IsInt, Min } from 'class-validator';

export class CreateDonationDto {
  @IsString()
  partnerId: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  amountNpr?: number;

  @IsOptional()
  @IsString()
  foodDescription?: string;
}

@Injectable()
export class DonationsService {
  constructor(private prisma: PrismaService) {}

  async getPartners() {
    return this.prisma.foodBankPartner.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    });
  }

  async donate(userId: string, dto: CreateDonationDto) {
    const partner = await this.prisma.foodBankPartner.findUnique({ where: { id: dto.partnerId } });
    if (!partner || !partner.isActive) throw new NotFoundException('Food bank partner not found');

    return this.prisma.foodBankDonation.create({
      data: {
        userId,
        partnerId: dto.partnerId,
        amountNpr: dto.amountNpr,
        foodDescription: dto.foodDescription,
        status: 'CONFIRMED',
      },
    });
  }

  async vendorDonate(userId: string, dto: CreateDonationDto) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) throw new NotFoundException('Vendor not found');
    const partner = await this.prisma.foodBankPartner.findUnique({ where: { id: dto.partnerId } });
    if (!partner || !partner.isActive) throw new NotFoundException('Food bank partner not found');

    return this.prisma.foodBankDonation.create({
      data: {
        vendorId: vendor.id,
        partnerId: dto.partnerId,
        amountNpr: dto.amountNpr,
        foodDescription: dto.foodDescription,
        status: 'CONFIRMED',
      },
    });
  }

  async getMyDonations(userId: string) {
    return this.prisma.foodBankDonation.findMany({
      where: { userId },
      include: { partner: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getPlatformStats() {
    const [totalDonations, totalAmountResult] = await Promise.all([
      this.prisma.foodBankDonation.count({ where: { status: 'CONFIRMED' } }),
      this.prisma.foodBankDonation.aggregate({
        where: { status: 'CONFIRMED', amountNpr: { not: null } },
        _sum: { amountNpr: true },
      }),
    ]);
    return {
      totalDonations,
      totalAmountNpr: totalAmountResult._sum.amountNpr ?? 0,
    };
  }

  // Admin: manage partners
  async createPartner(data: { name: string; description?: string; address?: string; logoUrl?: string; contactEmail?: string }) {
    return this.prisma.foodBankPartner.create({ data });
  }
}
