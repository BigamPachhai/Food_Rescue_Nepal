import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { DonationsService, CreateDonationDto } from './donations.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('donations')
export class DonationsController {
  constructor(private readonly donationsService: DonationsService) {}

  @Get('partners')
  getPartners() {
    return this.donationsService.getPartners();
  }

  @Get('stats')
  getStats() {
    return this.donationsService.getPlatformStats();
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  donate(@CurrentUser() user: any, @Body() dto: CreateDonationDto) {
    return this.donationsService.donate(user.id, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR')
  @Post('vendor')
  vendorDonate(@CurrentUser() user: any, @Body() dto: CreateDonationDto) {
    return this.donationsService.vendorDonate(user.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Get('my')
  getMyDonations(@CurrentUser() user: any) {
    return this.donationsService.getMyDonations(user.id);
  }
}
