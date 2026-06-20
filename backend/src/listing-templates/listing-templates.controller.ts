import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { ListingTemplatesService, SaveTemplateDto } from './listing-templates.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('VENDOR')
@Controller('listing-templates')
export class ListingTemplatesController {
  constructor(private readonly service: ListingTemplatesService) {}

  @Post()
  save(@CurrentUser() user: any, @Body() dto: SaveTemplateDto) {
    return this.service.save(user.id, dto);
  }

  @Get()
  getAll(@CurrentUser() user: any) {
    return this.service.getAll(user.id);
  }

  @Get(':id')
  getOne(@CurrentUser() user: any, @Param('id') id: string) {
    return this.service.getOne(user.id, id);
  }

  @Put(':id')
  update(@CurrentUser() user: any, @Param('id') id: string, @Body() dto: SaveTemplateDto) {
    return this.service.update(user.id, id, dto);
  }

  @Delete(':id')
  remove(@CurrentUser() user: any, @Param('id') id: string) {
    return this.service.remove(user.id, id);
  }
}
