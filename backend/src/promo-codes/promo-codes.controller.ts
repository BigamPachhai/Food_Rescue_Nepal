import { Controller, Post, Get, Delete, Patch, Body, Param, Query, UseGuards } from '@nestjs/common';
import { PromoCodesService } from './promo-codes.service';
import { CreatePromoCodeDto, ValidatePromoDto } from './dto/promo-code.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('promo-codes')
export class PromoCodesController {
  constructor(private readonly promoCodesService: PromoCodesService) {}

  @Post('validate')
  validate(@Body() dto: ValidatePromoDto) {
    return this.promoCodesService.validate(dto);
  }

  @UseGuards(RolesGuard)
  @Roles('VENDOR')
  @Post('my')
  createForVendor(@CurrentUser() user: any, @Body() dto: CreatePromoCodeDto) {
    return this.promoCodesService.createForVendor(user.id, dto);
  }

  @UseGuards(RolesGuard)
  @Roles('VENDOR')
  @Get('my')
  getMyPromoCodes(@CurrentUser() user: any, @Query('page') page: number, @Query('limit') limit: number) {
    return this.promoCodesService.getMyPromoCodes(user.id, page, limit);
  }

  @UseGuards(RolesGuard)
  @Roles('VENDOR')
  @Patch('my/:id/toggle')
  toggleByVendor(@CurrentUser() user: any, @Param('id') id: string) {
    return this.promoCodesService.toggleByVendor(user.id, id);
  }

  @UseGuards(RolesGuard)
  @Roles('VENDOR')
  @Delete('my/:id')
  removeByVendor(@CurrentUser() user: any, @Param('id') id: string) {
    return this.promoCodesService.removeByVendor(user.id, id);
  }

  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  @Post()
  create(@Body() dto: CreatePromoCodeDto) {
    return this.promoCodesService.create(dto);
  }

  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  @Get()
  getAll(@Query('page') page: number, @Query('limit') limit: number) {
    return this.promoCodesService.getAll(page, limit);
  }

  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  @Patch(':id/toggle')
  toggle(@Param('id') id: string) {
    return this.promoCodesService.toggle(id);
  }

  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.promoCodesService.remove(id);
  }
}
