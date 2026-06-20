import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { ReferralService } from './referral.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { IsString } from 'class-validator';

class ApplyReferralDto {
  @IsString()
  code: string;
}

@UseGuards(JwtAuthGuard)
@Controller('referral')
export class ReferralController {
  constructor(private readonly referralService: ReferralService) {}

  @Get('my-code')
  getMyCode(@CurrentUser() user: any) {
    return this.referralService.getOrCreateCode(user.id).then((code) => ({ referralCode: code }));
  }

  @Get('stats')
  getStats(@CurrentUser() user: any) {
    return this.referralService.getReferralStats(user.id);
  }

  @Post('apply')
  apply(@CurrentUser() user: any, @Body() dto: ApplyReferralDto) {
    return this.referralService.applyReferralCode(user.id, dto.code);
  }
}
