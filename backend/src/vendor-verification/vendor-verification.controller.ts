import { Controller, Post, Get, Patch, Body, Param, UseGuards, Query } from '@nestjs/common';
import { VendorVerificationService, UploadDocDto, ReviewDocDto } from './vendor-verification.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('verification')
export class VendorVerificationController {
  constructor(private readonly service: VendorVerificationService) {}

  @UseGuards(RolesGuard)
  @Roles('VENDOR')
  @Post()
  upload(@CurrentUser() user: any, @Body() dto: UploadDocDto) {
    return this.service.uploadDoc(user.id, dto);
  }

  @UseGuards(RolesGuard)
  @Roles('VENDOR')
  @Get('my')
  getMyDocs(@CurrentUser() user: any) {
    return this.service.getMyDocs(user.id);
  }

  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  @Get('pending')
  getPending(@Query('page') page: number, @Query('limit') limit: number) {
    return this.service.getPending(page, limit);
  }

  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  @Patch(':id/review')
  review(@CurrentUser() user: any, @Param('id') id: string, @Body() dto: ReviewDocDto) {
    return this.service.review(user.id, id, dto);
  }
}
