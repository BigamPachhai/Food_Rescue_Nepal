import {
  Controller,
  Get,
  Post,
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
@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('CUSTOMER' as any)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a review (CUSTOMER, requires PICKED_UP order)' })
  async create(@CurrentUser('id') userId: string, @Body() dto: CreateReviewDto) {
    const review = await this.reviewsService.create(userId, dto);
    return { success: true, data: review, message: 'Review submitted' };
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
}
