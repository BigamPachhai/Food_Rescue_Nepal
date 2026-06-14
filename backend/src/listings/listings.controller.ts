import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ListingsService } from './listings.service';
import { CreateListingDto } from './dto/create-listing.dto';
import { UpdateListingDto } from './dto/update-listing.dto';
import { ListingQueryDto } from './dto/listing-query.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('Listings')
@Controller('listings')
export class ListingsController {
  constructor(private readonly listingsService: ListingsService) {}

  @Get()
  @ApiOperation({ summary: 'Get active listings (public) with optional geo-filter' })
  async findAll(@Query() query: ListingQueryDto) {
    const result = await this.listingsService.findAll(query);
    return { success: true, data: result, message: 'Success' };
  }

  @Get('vendor/mine')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR' as any)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all listings for the authenticated vendor' })
  async getMyListings(@CurrentUser('id') userId: string) {
    const listings = await this.listingsService.getVendorListings(userId);
    return { success: true, data: listings, message: 'Success' };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get listing by ID (public)' })
  async findOne(@Param('id') id: string) {
    const listing = await this.listingsService.findOne(id);
    return { success: true, data: listing, message: 'Success' };
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR' as any)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new listing (VENDOR only)' })
  async create(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateListingDto,
  ) {
    const listing = await this.listingsService.create(userId, dto);
    return { success: true, data: listing, message: 'Listing created' };
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR' as any)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update own listing (VENDOR only)' })
  async update(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateListingDto,
  ) {
    const listing = await this.listingsService.update(id, userId, dto);
    return { success: true, data: listing, message: 'Listing updated' };
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR' as any)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Deactivate own listing (VENDOR only)' })
  async remove(@Param('id') id: string, @CurrentUser('id') userId: string) {
    const listing = await this.listingsService.remove(id, userId);
    return { success: true, data: listing, message: 'Listing deactivated' };
  }
}
