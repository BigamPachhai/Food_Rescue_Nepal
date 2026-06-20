import { Controller, Get, Put, Body, Param, UseGuards } from '@nestjs/common';
import { OperatingHoursService, BulkUpsertHoursDto } from './operating-hours.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('operating-hours')
export class OperatingHoursController {
  constructor(private readonly service: OperatingHoursService) {}

  @Get('vendor/:vendorId')
  getPublic(@Param('vendorId') vendorId: string) {
    return this.service.getPublic(vendorId);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR')
  @Get('my')
  getMy(@CurrentUser() user: any) {
    return this.service.get(user.id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR')
  @Put('my')
  upsert(@CurrentUser() user: any, @Body() dto: BulkUpsertHoursDto) {
    return this.service.bulkUpsert(user.id, dto);
  }
}
