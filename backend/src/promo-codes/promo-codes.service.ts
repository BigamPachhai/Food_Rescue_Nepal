import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePromoCodeDto, ValidatePromoDto } from './dto/promo-code.dto';

@Injectable()
export class PromoCodesService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreatePromoCodeDto) {
    return this.prisma.promoCode.create({
      data: {
        code: dto.code.toUpperCase().trim(),
        description: dto.description,
        discountType: dto.discountType,
        discountValue: dto.discountValue,
        minOrderAmount: dto.minOrderAmount ?? 0,
        maxUses: dto.maxUses,
        expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : null,
        vendorId: dto.vendorId,
      },
    });
  }

  async validate(dto: ValidatePromoDto) {
    const promo = await this.prisma.promoCode.findUnique({
      where: { code: dto.code.toUpperCase().trim() },
    });

    if (!promo || !promo.isActive) {
      throw new NotFoundException('Promo code not found or inactive');
    }

    if (promo.expiresAt && promo.expiresAt < new Date()) {
      throw new BadRequestException('Promo code has expired');
    }

    if (promo.maxUses !== null && promo.usedCount >= promo.maxUses) {
      throw new BadRequestException('Promo code usage limit reached');
    }

    if (dto.orderAmount < promo.minOrderAmount) {
      throw new BadRequestException(
        `Minimum order amount is Rs. ${promo.minOrderAmount} for this promo`,
      );
    }

    const discount =
      promo.discountType === 'PERCENT'
        ? Math.floor((dto.orderAmount * promo.discountValue) / 100)
        : Math.min(promo.discountValue, dto.orderAmount);

    return {
      valid: true,
      promoCodeId: promo.id,
      discountAmount: discount,
      finalAmount: dto.orderAmount - discount,
      description: promo.description,
    };
  }

  async getAll(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      this.prisma.promoCode.findMany({ skip, take: limit, orderBy: { createdAt: 'desc' } }),
      this.prisma.promoCode.count(),
    ]);
    return { items, total, page, limit };
  }

  async toggle(id: string) {
    const promo = await this.prisma.promoCode.findUnique({ where: { id } });
    if (!promo) throw new NotFoundException('Promo code not found');
    return this.prisma.promoCode.update({
      where: { id },
      data: { isActive: !promo.isActive },
    });
  }

  async remove(id: string) {
    await this.prisma.promoCode.findUniqueOrThrow({ where: { id } });
    return this.prisma.promoCode.delete({ where: { id } });
  }
}
