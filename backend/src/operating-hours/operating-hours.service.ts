import { Injectable, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { IsInt, IsString, IsBoolean, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';

export class UpsertHoursDto {
  @IsInt() @Min(0) @Max(6)
  dayOfWeek: number;

  @IsString()
  openTime: string;

  @IsString()
  closeTime: string;

  @IsBoolean()
  isClosed: boolean;
}

export class BulkUpsertHoursDto {
  @Type(() => UpsertHoursDto)
  hours: UpsertHoursDto[];
}

@Injectable()
export class OperatingHoursService {
  constructor(private prisma: PrismaService) {}

  private async getVendor(userId: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) throw new ForbiddenException('Vendor profile not found');
    return vendor;
  }

  async get(userId: string) {
    const vendor = await this.getVendor(userId);
    const hours = await this.prisma.operatingHours.findMany({
      where: { vendorId: vendor.id },
      orderBy: { dayOfWeek: 'asc' },
    });
    // Fill missing days with defaults
    const defaults = [0, 1, 2, 3, 4, 5, 6].map((day) => {
      const found = hours.find((h) => h.dayOfWeek === day);
      return found ?? { vendorId: vendor.id, dayOfWeek: day, openTime: '09:00', closeTime: '18:00', isClosed: false };
    });
    return defaults;
  }

  async getPublic(vendorId: string) {
    return this.prisma.operatingHours.findMany({
      where: { vendorId },
      orderBy: { dayOfWeek: 'asc' },
    });
  }

  async bulkUpsert(userId: string, dto: BulkUpsertHoursDto) {
    const vendor = await this.getVendor(userId);
    return this.prisma.$transaction(
      dto.hours.map((h) =>
        this.prisma.operatingHours.upsert({
          where: { vendorId_dayOfWeek: { vendorId: vendor.id, dayOfWeek: h.dayOfWeek } },
          create: { vendorId: vendor.id, dayOfWeek: h.dayOfWeek, openTime: h.openTime, closeTime: h.closeTime, isClosed: h.isClosed },
          update: { openTime: h.openTime, closeTime: h.closeTime, isClosed: h.isClosed },
        }),
      ),
    );
  }

  async isVendorOpenNow(vendorId: string): Promise<boolean> {
    const now = new Date();
    const day = now.getDay();
    const timeStr = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;

    const hours = await this.prisma.operatingHours.findUnique({
      where: { vendorId_dayOfWeek: { vendorId, dayOfWeek: day } },
    });

    if (!hours) return true; // no schedule set = always open
    if (hours.isClosed) return false;
    return timeStr >= hours.openTime && timeStr <= hours.closeTime;
  }
}
