import { Controller, Post, Get, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { FlashSalesService } from './flash-sales.service';
import { CreateFlashSaleDto } from './dto/flash-sale.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('flash-sales')
export class FlashSalesController {
  constructor(private readonly flashSalesService: FlashSalesService) {}

  @Get()
  getActive(@Query('page') page: number, @Query('limit') limit: number) {
    return this.flashSalesService.getActive(page, limit);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR')
  @Post()
  create(@CurrentUser() user: any, @Body() dto: CreateFlashSaleDto) {
    return this.flashSalesService.create(user.id, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR')
  @Get('my')
  getMy(@CurrentUser() user: any) {
    return this.flashSalesService.getUpcoming(user.id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR')
  @Delete(':id')
  cancel(@CurrentUser() user: any, @Param('id') id: string) {
    return this.flashSalesService.cancel(user.id, id);
  }
}
