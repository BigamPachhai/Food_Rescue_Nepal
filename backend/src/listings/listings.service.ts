import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateListingDto } from './dto/create-listing.dto';
import { UpdateListingDto } from './dto/update-listing.dto';
import { ListingQueryDto } from './dto/listing-query.dto';
import { VendorStatus } from '@prisma/client';

const VENDOR_SELECT = {
  id: true, businessName: true, address: true, lat: true, lng: true,
  logoUrl: true, avgRating: true, totalReviews: true, isOpen: true, isVerified: true,
} as const;

@Injectable()
export class ListingsService {
  constructor(private prisma: PrismaService) {}

  async findAll(query: ListingQueryDto) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    // Build vendor condition
    const vendorCondition: any = { status: VendorStatus.APPROVED, isOpen: true };
    if (query.minRating != null) {
      vendorCondition.avgRating = { gte: query.minRating };
    }

    // Build listing WHERE clause
    const where: any = {
      isActive: true,
      vendor: vendorCondition,
      ...(query.category && { category: query.category }),
      ...(query.onlyAvailable && { availableQty: { gt: 0 } }),
      ...(query.vendorId && { vendorId: query.vendorId }),
      ...(query.featuredOnly && { isFeatured: true }),
    };

    // Allergen exclusion filter
    if (query.excludeAllergens) {
      const excluded = query.excludeAllergens.split(',').map((a) => a.trim());
      where.allergens = { isEmpty: false };
      // Exclude listings that contain any of the specified allergens
      where.NOT = excluded.map((allergen) => ({
        allergens: { has: allergen },
      }));
    }

    // Price range filter
    if (query.minPrice != null || query.maxPrice != null) {
      where.discountedPrice = {
        ...(query.minPrice != null && { gte: query.minPrice }),
        ...(query.maxPrice != null && { lte: query.maxPrice }),
      };
    }

    // Search: match name, description, or vendor business name
    // Using AND wrapping OR to avoid bypassing the top-level vendor status filter
    if (query.search) {
      where.AND = [
        {
          OR: [
            { name: { contains: query.search, mode: 'insensitive' } },
            { description: { contains: query.search, mode: 'insensitive' } },
            { vendor: { businessName: { contains: query.search, mode: 'insensitive' } } },
          ],
        },
      ];
    }

    const listings = await this.prisma.listing.findMany({
      where,
      include: { vendor: { select: VENDOR_SELECT } },
      orderBy: query.trending ? { trendingScore: 'desc' } : { createdAt: 'desc' },
    });

    // Increment view count async
    setImmediate(async () => {});


    // Apply distance and sort in-memory
    let result: any[] = listings;

    if (query.lat != null && query.lng != null) {
      const radius = query.radius || 50;
      result = listings
        .filter((l) => l.vendor.lat != null && l.vendor.lng != null)
        .map((l) => ({
          ...l,
          distance: this.haversine(query.lat!, query.lng!, l.vendor.lat!, l.vendor.lng!),
        }))
        .filter((l) => l.distance <= radius);
    }

    // Apply sort
    const sortBy = query.sortBy || 'newest';
    switch (sortBy) {
      case 'nearest':
        if (query.lat != null) result.sort((a, b) => (a.distance ?? 0) - (b.distance ?? 0));
        break;
      case 'price_asc':
        result.sort((a, b) => a.discountedPrice - b.discountedPrice);
        break;
      case 'price_desc':
        result.sort((a, b) => b.discountedPrice - a.discountedPrice);
        break;
      case 'discount':
        result.sort((a, b) => {
          const dA = a.originalPrice > 0 ? (a.originalPrice - a.discountedPrice) / a.originalPrice : 0;
          const dB = b.originalPrice > 0 ? (b.originalPrice - b.discountedPrice) / b.originalPrice : 0;
          return dB - dA;
        });
        break;
      case 'popular':
        result.sort((a, b) => (b.vendor?.avgRating ?? 0) - (a.vendor?.avgRating ?? 0));
        break;
      case 'newest':
      default:
        // already sorted by createdAt desc from DB
        break;
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

    // Increment view count
    setImmediate(async () => {
      try {
        await this.prisma.listing.update({
          where: { id },
          data: { viewCount: { increment: 1 }, trendingScore: { increment: 0.1 } },
        });
      } catch (_) {}
    });

    return listing;
  }

  async getRecommendations(userId: string, limit = 10) {
    // Get categories user has ordered from
    const pastOrders = await this.prisma.order.findMany({
      where: { customerId: userId, status: 'COMPLETED' },
      include: { listing: { select: { category: true, dietaryTags: true } } },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });

    const preferredCategories = [...new Set(pastOrders.map((o) => o.listing.category))];
    const preferredTags = [...new Set(pastOrders.flatMap((o) => o.listing.dietaryTags))];
    const orderedListingIds = pastOrders.map((o) => o.listingId);

    const where: any = {
      isActive: true,
      availableQty: { gt: 0 },
      id: { notIn: orderedListingIds },
      vendor: { status: VendorStatus.APPROVED, isOpen: true },
    };

    if (preferredCategories.length > 0) {
      where.OR = [
        { category: { in: preferredCategories } },
        { dietaryTags: { hasSome: preferredTags } },
      ];
    }

    return this.prisma.listing.findMany({
      where,
      include: { vendor: { select: VENDOR_SELECT } },
      orderBy: [{ trendingScore: 'desc' }, { createdAt: 'desc' }],
      take: limit,
    });
  }

  async autocomplete(query: string, limit = 8) {
    if (!query || query.trim().length < 2) return [];

    const listings = await this.prisma.listing.findMany({
      where: {
        isActive: true,
        OR: [
          { name: { contains: query, mode: 'insensitive' } },
          { vendor: { businessName: { contains: query, mode: 'insensitive' }, status: VendorStatus.APPROVED } },
        ],
      },
      select: { id: true, name: true, vendor: { select: { businessName: true } } },
      take: limit,
    });

    const suggestions = [
      ...new Set([
        ...listings.map((l) => l.name),
        ...listings.map((l) => l.vendor.businessName),
      ]),
    ].slice(0, limit);

    return suggestions;
  }

  async recalcTrendingScore(listingId: string) {
    const listing = await this.prisma.listing.findUnique({
      where: { id: listingId },
      include: { orders: { where: { status: 'COMPLETED' } } },
    });
    if (!listing) return;

    const orderCount = listing.orders.length;
    const viewScore = listing.viewCount * 0.01;
    const orderScore = orderCount * 2;
    const recencyDays = (Date.now() - listing.createdAt.getTime()) / (1000 * 60 * 60 * 24);
    const decayFactor = Math.exp(-recencyDays / 14); // 2-week half-life

    const score = (viewScore + orderScore) * (listing.isFeatured ? 1.5 : 1) * decayFactor;

    await this.prisma.listing.update({ where: { id: listingId }, data: { trendingScore: score } });
  }

  async create(userId: string, dto: CreateListingDto) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) {
      throw new ForbiddenException('Vendor profile not found');
    }

    if (vendor.status !== VendorStatus.APPROVED) {
      throw new ForbiddenException('Only approved vendors can create listings');
    }

    const pickupStart = new Date(dto.pickupStart);
    const pickupEnd = new Date(dto.pickupEnd);
    if (pickupEnd <= pickupStart) {
      throw new BadRequestException('Pickup end time must be after pickup start time');
    }
    if (dto.discountedPrice >= dto.originalPrice) {
      throw new BadRequestException('Discounted price must be less than original price');
    }
    if (dto.discountedPrice <= 0) {
      throw new BadRequestException('Discounted price must be greater than 0');
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
        pickupStart,
        pickupEnd,
        imageUrls: dto.imageUrls || [],
        dietaryTags: dto.dietaryTags || [],
        ...(dto.expiryTime && { expiryTime: new Date(dto.expiryTime) }),
        ...(dto.conditionNotes !== undefined && { conditionNotes: dto.conditionNotes }),
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

    // Validate prices if either is being updated
    const finalOriginal = dto.originalPrice ?? listing.originalPrice;
    const finalDiscounted = dto.discountedPrice ?? listing.discountedPrice;
    if (dto.originalPrice != null || dto.discountedPrice != null) {
      if (finalDiscounted >= finalOriginal) {
        throw new BadRequestException('Discounted price must be less than original price');
      }
    }

    // Validate pickup window if either time is being updated
    if (dto.pickupStart || dto.pickupEnd) {
      const finalStart = dto.pickupStart ? new Date(dto.pickupStart) : listing.pickupStart;
      const finalEnd = dto.pickupEnd ? new Date(dto.pickupEnd) : listing.pickupEnd;
      if (finalEnd <= finalStart) {
        throw new BadRequestException('Pickup end time must be after pickup start time');
      }
    }

    // When re-activating a sold-out listing, restore availableQty to quantity
    const restoreQty =
      dto.isActive === true &&
      !listing.isActive &&
      listing.availableQty === 0 &&
      dto.availableQty == null;

    // When quantity changes without an explicit availableQty, adjust availableQty
    // to preserve the number of in-flight reservations (reserved = quantity - availableQty)
    let derivedAvailableQty: number | undefined;
    if (dto.quantity != null && dto.availableQty == null && !restoreQty) {
      const reserved = listing.quantity - listing.availableQty;
      derivedAvailableQty = Math.max(0, dto.quantity - reserved);
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
        ...(dto.availableQty != null
          ? { availableQty: dto.availableQty }
          : restoreQty
          ? { availableQty: listing.quantity }
          : derivedAvailableQty != null
          ? { availableQty: derivedAvailableQty }
          : {}),
        ...(dto.pickupStart && { pickupStart: new Date(dto.pickupStart) }),
        ...(dto.pickupEnd && { pickupEnd: new Date(dto.pickupEnd) }),
        ...(dto.imageUrls && { imageUrls: dto.imageUrls }),
        ...(dto.dietaryTags !== undefined && { dietaryTags: dto.dietaryTags }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
        ...(dto.expiryTime !== undefined && { expiryTime: dto.expiryTime ? new Date(dto.expiryTime) : null }),
        ...(dto.conditionNotes !== undefined && { conditionNotes: dto.conditionNotes }),
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
