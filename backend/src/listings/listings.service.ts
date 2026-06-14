import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateListingDto } from './dto/create-listing.dto';
import { UpdateListingDto } from './dto/update-listing.dto';
import { ListingQueryDto } from './dto/listing-query.dto';
import { VendorStatus } from '@prisma/client';

@Injectable()
export class ListingsService {
  constructor(private prisma: PrismaService) {}

  async findAll(query: ListingQueryDto) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = {
      isActive: true,
      vendor: { status: VendorStatus.APPROVED },
      ...(query.category && { category: query.category }),
      ...(query.search && {
        OR: [
          { name: { contains: query.search, mode: 'insensitive' } },
          { description: { contains: query.search, mode: 'insensitive' } },
        ],
      }),
    };

    const listings = await this.prisma.listing.findMany({
      where,
      include: {
        vendor: {
          select: {
            id: true,
            businessName: true,
            address: true,
            lat: true,
            lng: true,
            logoUrl: true,
            avgRating: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    // Apply distance filtering and sorting if lat/lng provided
    let result = listings;
    if (query.lat != null && query.lng != null) {
      const radius = query.radius || 10;
      result = listings
        .map((l) => ({
          ...l,
          distance: this.haversine(query.lat!, query.lng!, l.vendor.lat, l.vendor.lng),
        }))
        .filter((l) => (l as any).distance <= radius)
        .sort((a, b) => (a as any).distance - (b as any).distance);
    }

    const total = result.length;
    const paginated = result.slice(skip, skip + limit);

    return {
      listings: paginated,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findOne(id: string) {
    const listing = await this.prisma.listing.findUnique({
      where: { id },
      include: {
        vendor: {
          select: {
            id: true,
            businessName: true,
            address: true,
            lat: true,
            lng: true,
            logoUrl: true,
            avgRating: true,
            totalReviews: true,
            status: true,
          },
        },
      },
    });

    if (!listing) {
      throw new NotFoundException('Listing not found');
    }

    return listing;
  }

  async create(userId: string, dto: CreateListingDto) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) {
      throw new ForbiddenException('Vendor profile not found');
    }

    if (vendor.status === VendorStatus.SUSPENDED) {
      throw new ForbiddenException('Suspended vendors cannot create listings');
    }

    return this.prisma.listing.create({
      data: {
        vendorId: vendor.id,
        name: dto.name,
        description: dto.description,
        category: dto.category,
        originalPrice: dto.originalPrice,
        discountedPrice: dto.discountedPrice,
        quantity: dto.quantity,
        availableQty: dto.quantity,
        pickupStart: new Date(dto.pickupStart),
        pickupEnd: new Date(dto.pickupEnd),
        imageUrls: dto.imageUrls || [],
      },
    });
  }

  async update(id: string, userId: string, dto: UpdateListingDto) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) {
      throw new ForbiddenException('Vendor profile not found');
    }

    const listing = await this.prisma.listing.findUnique({ where: { id } });
    if (!listing) {
      throw new NotFoundException('Listing not found');
    }

    if (listing.vendorId !== vendor.id) {
      throw new ForbiddenException('You do not own this listing');
    }

    return this.prisma.listing.update({
      where: { id },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.category && { category: dto.category }),
        ...(dto.originalPrice != null && { originalPrice: dto.originalPrice }),
        ...(dto.discountedPrice != null && { discountedPrice: dto.discountedPrice }),
        ...(dto.quantity != null && { quantity: dto.quantity }),
        ...(dto.availableQty != null && { availableQty: dto.availableQty }),
        ...(dto.pickupStart && { pickupStart: new Date(dto.pickupStart) }),
        ...(dto.pickupEnd && { pickupEnd: new Date(dto.pickupEnd) }),
        ...(dto.imageUrls && { imageUrls: dto.imageUrls }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
      },
    });
  }

  async remove(id: string, userId: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) {
      throw new ForbiddenException('Vendor profile not found');
    }

    const listing = await this.prisma.listing.findUnique({ where: { id } });
    if (!listing) {
      throw new NotFoundException('Listing not found');
    }

    if (listing.vendorId !== vendor.id) {
      throw new ForbiddenException('You do not own this listing');
    }

    return this.prisma.listing.update({
      where: { id },
      data: { isActive: false },
    });
  }

  async getVendorListings(userId: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) {
      throw new ForbiddenException('Vendor profile not found');
    }

    return this.prisma.listing.findMany({
      where: { vendorId: vendor.id },
      orderBy: { createdAt: 'desc' },
    });
  }

  private haversine(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371;
    const dLat = this.toRad(lat2 - lat1);
    const dLng = this.toRad(lng2 - lng1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRad(lat1)) *
        Math.cos(this.toRad(lat2)) *
        Math.sin(dLng / 2) *
        Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private toRad(deg: number): number {
    return deg * (Math.PI / 180);
  }
}
