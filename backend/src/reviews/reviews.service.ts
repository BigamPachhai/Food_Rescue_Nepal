import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { OrderStatus } from '@prisma/client';

@Injectable()
export class ReviewsService {
  constructor(private prisma: PrismaService) {}

  async create(customerId: string, dto: CreateReviewDto) {
    const order = await this.prisma.order.findUnique({
      where: { id: dto.orderId },
      include: { review: true },
    });

    if (!order) throw new NotFoundException('Order not found');
    if (order.customerId !== customerId) {
      throw new BadRequestException('This is not your order');
    }
    if (order.status !== OrderStatus.PICKED_UP) {
      throw new BadRequestException('Can only review PICKED_UP orders');
    }
    if (order.review) {
      throw new ConflictException('You have already reviewed this order');
    }

    const review = await this.prisma.review.create({
      data: {
        customerId,
        vendorId: order.vendorId,
        orderId: dto.orderId,
        rating: dto.rating,
        comment: dto.comment,
      },
      include: {
        customer: { select: { name: true, avatarUrl: true } },
        vendor: { select: { businessName: true } },
      },
    });

    // Update vendor's average rating
    const allReviews = await this.prisma.review.aggregate({
      where: { vendorId: order.vendorId },
      _avg: { rating: true },
      _count: { rating: true },
    });

    await this.prisma.vendor.update({
      where: { id: order.vendorId },
      data: {
        avgRating: allReviews._avg.rating || 0,
        totalReviews: allReviews._count.rating,
      },
    });

    return review;
  }

  async getVendorReviews(vendorId: string, page: number = 1, limit: number = 20) {
    const skip = (page - 1) * limit;
    const [reviews, total] = await Promise.all([
      this.prisma.review.findMany({
        where: { vendorId },
        include: {
          customer: { select: { name: true, avatarUrl: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.review.count({ where: { vendorId } }),
    ]);
    return { reviews, total, page, limit };
  }
}
