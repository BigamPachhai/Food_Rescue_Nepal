import { Controller, Post, Get, Patch, Body, Param, Query, UseGuards } from '@nestjs/common';
import { DisputesService, CreateDisputeDto, ResolveDisputeDto } from './disputes.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('disputes')
export class DisputesController {
  constructor(private readonly disputesService: DisputesService) {}

  @Post()
  create(@CurrentUser() user: any, @Body() dto: CreateDisputeDto) {
    return this.disputesService.create(user.id, dto);
  }

  @Get('my')
  getMy(@CurrentUser() user: any) {
    return this.disputesService.getMyDisputes(user.id);
  }

  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  @Get()
  getAll(@Query('page') page: number, @Query('limit') limit: number, @Query('status') status: any) {
    return this.disputesService.getAll(page, limit, status);
  }

  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  @Patch(':id/resolve')
  resolve(@CurrentUser() user: any, @Param('id') id: string, @Body() dto: ResolveDisputeDto) {
    return this.disputesService.resolve(user.id, id, dto);
  }
}
