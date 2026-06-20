import { Controller, Post, Delete, Get, Param, UseGuards } from '@nestjs/common';
import { WaitlistService } from './waitlist.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('waitlist')
export class WaitlistController {
  constructor(private readonly waitlistService: WaitlistService) {}

  @Post(':listingId')
  join(@CurrentUser() user: any, @Param('listingId') listingId: string) {
    return this.waitlistService.join(user.id, listingId);
  }

  @Delete(':listingId')
  leave(@CurrentUser() user: any, @Param('listingId') listingId: string) {
    return this.waitlistService.leave(user.id, listingId);
  }

  @Get('my')
  getMyWaitlist(@CurrentUser() user: any) {
    return this.waitlistService.getMyWaitlist(user.id);
  }

  @Get(':listingId/status')
  status(@CurrentUser() user: any, @Param('listingId') listingId: string) {
    return this.waitlistService.isOnWaitlist(user.id, listingId);
  }
}
