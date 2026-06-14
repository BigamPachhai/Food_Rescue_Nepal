import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
  ForbiddenException,
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
    if (order.customerId !== customerId)
      throw new BadRequestException('This is not your order');
    if (order.status !== OrderStatus.PICKED_UP)
      throw new BadRequestException('Can only review PICKED_UP orders');
    if (order.review)
      throw new ConflictException('You have already reviewed this order');

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

    await this._recalcVendorRating(order.vendorId);
    return review;
  }

  async update(reviewId: string, customerId: string, rating: number, comment?: string) {
    const review = await this.prisma.review.findUnique({ where: { id: reviewId } });
    if (!review) throw new NotFoundException('Review not found');
    if (review.customerId !== customerId)
      throw new ForbiddenException('This is not your review');

    return this.prisma.review.update({
      where: { id: reviewId },
      data: { rating, comment, updatedAt: new Date() },
      include: { customer: { select: { name: true, avatarUrl: true } } },
    });
  }

  async delete(reviewId: string, customerId: string) {
    const review = await this.prisma.review.findUnique({ where: { id: reviewId } });
    if (!review) throw new NotFoundException('Review not found');
    if (review.customerId !== customerId)
      throw new ForbiddenException('This is not your review');

    await this.prisma.review.delete({ where: { id: reviewId } });
    await this._recalcVendorRating(review.vendorId);
    return { deleted: true };
  }

  async getMyReviews(customerId: string) {
    return this.prisma.review.findMany({
      where: { customerId },
      include: {
        vendor: { select: { id: true, businessName: true, logoUrl: true } },
        order: { select: { id: true, createdAt: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getByOrderId(orderId: string) {
    return this.prisma.review.findUnique({
      where: { orderId },
      include: { customer: { select: { name: true, avatarUrl: true } } },
    });
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

  async respondToReview(reviewId: string, vendorUserId: string, response: string) {
    const review = await this.prisma.review.findUnique({
      where: { id: reviewId },
      include: { vendor: { select: { userId: true } } },
    });
    if (!review) throw new NotFoundException('Review not found');
    if (review.vendor.userId !== vendorUserId)
      throw new ForbiddenException('Not your vendor');

    return this.prisma.review.update({
      where: { id: reviewId },
      data: { vendorResponse: response, vendorRespondedAt: new Date() },
    });
  }

  private async _recalcVendorRating(vendorId: string) {
    const agg = await this.prisma.review.aggregate({
      where: { vendorId },
      _avg: { rating: true },
      _count: { rating: true },
    });
    await this.prisma.vendor.update({
      where: { id: vendorId },
      data: {
        avgRating: agg._avg.rating ?? 0,
        totalReviews: agg._count.rating,
      },
    });
  }
}
