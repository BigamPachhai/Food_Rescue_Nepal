import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { LoyaltyService } from './loyalty.service';
import { RedeemPointsDto } from './dto/loyalty.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('loyalty')
export class LoyaltyController {
  constructor(private readonly loyaltyService: LoyaltyService) {}

  @Get()
  getBalance(@CurrentUser() user: any) {
    return this.loyaltyService.getBalance(user.id);
  }

  @Post('redeem')
  redeem(@CurrentUser() user: any, @Body() dto: RedeemPointsDto) {
    return this.loyaltyService.redeemPoints(user.id, dto.points, dto.orderId);
  }
}
