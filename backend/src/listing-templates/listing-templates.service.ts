import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { IsString, IsObject } from 'class-validator';

export class SaveTemplateDto {
  @IsString()
  name: string;

  @IsObject()
  templateData: Record<string, any>;
}

@Injectable()
export class ListingTemplatesService {
  constructor(private prisma: PrismaService) {}

  private async getVendor(userId: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) throw new ForbiddenException('Vendor profile not found');
    return vendor;
  }

  async save(userId: string, dto: SaveTemplateDto) {
    const vendor = await this.getVendor(userId);
    return this.prisma.listingTemplate.create({
      data: { vendorId: vendor.id, name: dto.name, templateData: dto.templateData },
    });
  }

  async getAll(userId: string) {
    const vendor = await this.getVendor(userId);
    return this.prisma.listingTemplate.findMany({
      where: { vendorId: vendor.id },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async getOne(userId: string, templateId: string) {
    const vendor = await this.getVendor(userId);
    const template = await this.prisma.listingTemplate.findUnique({ where: { id: templateId } });
    if (!template || template.vendorId !== vendor.id) throw new NotFoundException('Template not found');
    return template;
  }

  async update(userId: string, templateId: string, dto: SaveTemplateDto) {
    const vendor = await this.getVendor(userId);
    const template = await this.prisma.listingTemplate.findUnique({ where: { id: templateId } });
    if (!template || template.vendorId !== vendor.id) throw new NotFoundException('Template not found');
    return this.prisma.listingTemplate.update({
      where: { id: templateId },
      data: { name: dto.name, templateData: dto.templateData },
    });
  }

  async remove(userId: string, templateId: string) {
    const vendor = await this.getVendor(userId);
    const template = await this.prisma.listingTemplate.findUnique({ where: { id: templateId } });
    if (!template || template.vendorId !== vendor.id) throw new NotFoundException('Template not found');
    return this.prisma.listingTemplate.delete({ where: { id: templateId } });
  }
}
