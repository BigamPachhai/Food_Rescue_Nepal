import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  DefaultValuePipe,
  ParseIntPipe,
} from '@nestjs/common';
import { ReviewsService } from './reviews.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('Reviews')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles('CUSTOMER' as any)
  @ApiOperation({ summary: 'Create a review (requires PICKED_UP order)' })
  async create(@CurrentUser('id') userId: string, @Body() dto: CreateReviewDto) {
    const review = await this.reviewsService.create(userId, dto);
    return { success: true, data: review, message: 'Review submitted' };
  }

  @Get('my')
  @UseGuards(RolesGuard)
  @Roles('CUSTOMER' as any)
  @ApiOperation({ summary: 'Get my reviews' })
  async getMyReviews(@CurrentUser('id') userId: string) {
    const reviews = await this.reviewsService.getMyReviews(userId);
    return { success: true, data: reviews, message: 'Success' };
  }

  @Get('order/:orderId')
  @ApiOperation({ summary: 'Get review for a specific order' })
  async getByOrder(@Param('orderId') orderId: string) {
    const review = await this.reviewsService.getByOrderId(orderId);
    return { success: true, data: review, message: 'Success' };
  }

  @Get('vendor/:id')
  @ApiOperation({ summary: 'Get paginated reviews for a vendor (public)' })
  async getVendorReviews(
    @Param('id') vendorId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    const result = await this.reviewsService.getVendorReviews(vendorId, page, limit);
    return { success: true, data: result, message: 'Success' };
  }

  @Put(':id')
  @UseGuards(RolesGuard)
  @Roles('CUSTOMER' as any)
  @ApiOperation({ summary: 'Edit my review' })
  async update(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body() body: { rating: number; comment?: string },
  ) {
    const review = await this.reviewsService.update(id, userId, body.rating, body.comment);
    return { success: true, data: review, message: 'Review updated' };
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles('CUSTOMER' as any)
  @ApiOperation({ summary: 'Delete my review' })
  async delete(@Param('id') id: string, @CurrentUser('id') userId: string) {
    const result = await this.reviewsService.delete(id, userId);
    return { success: true, data: result, message: 'Review deleted' };
  }

  @Patch(':id/respond')
  @UseGuards(RolesGuard)
  @Roles('VENDOR' as any)
  @ApiOperation({ summary: 'Vendor responds to a review' })
  async respond(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body('response') response: string,
  ) {
    const review = await this.reviewsService.respondToReview(id, userId, response);
    return { success: true, data: review, message: 'Response saved' };
  }
}
