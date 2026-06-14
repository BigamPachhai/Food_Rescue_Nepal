import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export interface CreateReportDto {
  type: string;
  targetId?: string;
  reason: string;
  description?: string;
}

@Injectable()
export class ReportsService {
  constructor(private prisma: PrismaService) {}

  async create(reporterId: string, dto: CreateReportDto) {
    return this.prisma.report.create({
      data: {
        reporterId,
        type: dto.type,
        targetId: dto.targetId,
        reason: dto.reason,
        description: dto.description,
      },
    });
  }
}
