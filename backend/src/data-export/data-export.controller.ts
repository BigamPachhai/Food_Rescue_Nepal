import { Controller, Post, Get, Delete, Param, UseGuards } from '@nestjs/common';
import { DataExportService } from './data-export.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('data')
export class DataExportController {
  constructor(private readonly dataExportService: DataExportService) {}

  @Post('export')
  requestExport(@CurrentUser() user: any) {
    return this.dataExportService.requestExport(user.id);
  }

  @Get('export')
  getMyRequests(@CurrentUser() user: any) {
    return this.dataExportService.getMyRequests(user.id);
  }

  @Get('export/:id')
  getStatus(@CurrentUser() user: any, @Param('id') id: string) {
    return this.dataExportService.getStatus(user.id, id);
  }

  @Delete('account')
  deleteAccount(@CurrentUser() user: any) {
    return this.dataExportService.deleteAccount(user.id);
  }
}
