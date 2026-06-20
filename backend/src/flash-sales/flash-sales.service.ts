import { Injectable, ForbiddenException, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateFlashSaleDto } from './dto/flash-sale.dto';

@Injectable()
export class FlashSalesService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateFlashSaleDto) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) throw new ForbiddenException('Vendor profile not found');

    const listing = await this.prisma.listing.findUnique({ where: { id: dto.listingId } });
    if (!listing || listing.vendorId !== vendor.id) throw new NotFoundException('Listing not found');

    const startsAt = new Date(dto.startsAt);
    const endsAt = new Date(dto.endsAt);
    if (endsAt <= startsAt) throw new BadRequestException('End time must be after start time');
    if (dto.salePrice >= listing.discountedPrice) {
      throw new BadRequestException('Flash sale price must be lower than current discounted price');
    }

    return this.prisma.flashSale.create({
      data: {
        vendorId: vendor.id,
        listingId: dto.listingId,
        salePrice: dto.salePrice,
        originalPrice: listing.discountedPrice,
        startsAt,
        endsAt,
      },
    });
  }

  async getActive(page = 1, limit = 20) {
    const now = new Date();
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      this.prisma.flashSale.findMany({
        where: { isActive: true, startsAt: { lte: now }, endsAt: { gte: now } },
        include: {
          listing: {
            select: { id: true, name: true, imageUrls: true, category: true, availableQty: true, dietaryTags: true },
          },
          vendor: { select: { id: true, businessName: true, logoUrl: true, address: true } },
        },
        orderBy: { endsAt: 'asc' },
        skip,
        take: limit,
      }),
      this.prisma.flashSale.count({
        where: { isActive: true, startsAt: { lte: now }, endsAt: { gte: now } },
      }),
    ]);
    return { items, total, page, limit };
  }

  async getUpcoming(vendorUserId: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId: vendorUserId } });
    if (!vendor) throw new ForbiddenException('Vendor profile not found');
    const now = new Date();
    return this.prisma.flashSale.findMany({
      where: { vendorId: vendor.id, endsAt: { gte: now } },
      include: { listing: { select: { name: true } } },
      orderBy: { startsAt: 'asc' },
    });
  }

  async cancel(userId: string, id: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) throw new ForbiddenException('Vendor profile not found');

    const sale = await this.prisma.flashSale.findUnique({ where: { id } });
    if (!sale || sale.vendorId !== vendor.id) throw new NotFoundException('Flash sale not found');

    return this.prisma.flashSale.update({ where: { id }, data: { isActive: false } });
  }
}
