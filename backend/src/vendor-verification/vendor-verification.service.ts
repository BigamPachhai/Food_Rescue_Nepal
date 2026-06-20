import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { VerificationStatus } from '@prisma/client';
import { IsString, IsOptional, IsIn } from 'class-validator';

export class UploadDocDto {
  @IsIn(['BUSINESS_REG', 'TAX', 'ID', 'OTHER'])
  docType: string;

  @IsString()
  docUrl: string;
}

export class ReviewDocDto {
  @IsIn(['APPROVED', 'REJECTED'])
  status: VerificationStatus;

  @IsOptional()
  @IsString()
  adminNote?: string;
}

@Injectable()
export class VendorVerificationService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  async uploadDoc(userId: string, dto: UploadDocDto) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) throw new ForbiddenException('Vendor profile not found');

    return this.prisma.verificationDocument.create({
      data: { vendorId: vendor.id, docType: dto.docType, docUrl: dto.docUrl },
    });
  }

  async getMyDocs(userId: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) throw new ForbiddenException('Vendor profile not found');
    return this.prisma.verificationDocument.findMany({
      where: { vendorId: vendor.id },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getPending(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      this.prisma.verificationDocument.findMany({
        where: { status: VerificationStatus.PENDING },
        include: { vendor: { select: { businessName: true, userId: true } } },
        orderBy: { createdAt: 'asc' },
        skip,
        take: limit,
      }),
      this.prisma.verificationDocument.count({ where: { status: VerificationStatus.PENDING } }),
    ]);
    return { items, total, page, limit };
  }

  async review(adminId: string, docId: string, dto: ReviewDocDto) {
    const doc = await this.prisma.verificationDocument.findUnique({
      where: { id: docId },
      include: { vendor: { include: { user: { select: { id: true, fcmToken: true } } } } },
    });
    if (!doc) throw new NotFoundException('Document not found');

    const updated = await this.prisma.verificationDocument.update({
      where: { id: docId },
      data: { status: dto.status, adminNote: dto.adminNote, reviewedAt: new Date() },
    });

    // If all docs for this vendor approved, mark vendor as verified
    if (dto.status === VerificationStatus.APPROVED) {
      const pending = await this.prisma.verificationDocument.count({
        where: { vendorId: doc.vendorId, status: VerificationStatus.PENDING },
      });
      if (pending === 0) {
        await this.prisma.vendor.update({ where: { id: doc.vendorId }, data: { isVerified: true } });
      }
    }

    setImmediate(async () => {
      try {
        const status = dto.status === VerificationStatus.APPROVED ? '✅ Approved' : '❌ Rejected';
        await this.notificationsService.send({
          userId: doc.vendor.user.id,
          title: `Document ${status}`,
          body: dto.adminNote ?? `Your ${doc.docType} document has been reviewed.`,
          type: 'VERIFICATION_UPDATE',
          data: { docId },
          fcmToken: doc.vendor.user.fcmToken || undefined,
        });
      } catch (_) {}
    });

    return updated;
  }
}
