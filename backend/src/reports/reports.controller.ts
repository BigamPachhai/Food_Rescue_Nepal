import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('Reports')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Post()
  @ApiOperation({ summary: 'Submit a report (vendor, listing, or other)' })
  async create(
    @CurrentUser('id') userId: string,
    @Body() body: { type: string; targetId?: string; reason: string; description?: string },
  ) {
    const report = await this.reportsService.create(userId, body);
    return { success: true, data: report, message: 'Report submitted. Thank you.' };
  }
}
