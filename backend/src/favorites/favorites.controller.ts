import { Controller, Get, Post, Param, UseGuards } from '@nestjs/common';
import { FavoritesService } from './favorites.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('Favorites')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('CUSTOMER' as any)
@Controller('favorites')
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  @Post(':listingId')
  @ApiOperation({ summary: 'Toggle favorite listing (CUSTOMER only)' })
  async toggle(@CurrentUser('id') userId: string, @Param('listingId') listingId: string) {
    const result = await this.favoritesService.toggle(userId, listingId);
    const message = result.favorited ? 'Added to favorites' : 'Removed from favorites';
    return { success: true, data: result, message };
  }

  @Get()
  @ApiOperation({ summary: 'Get my favorite listings (CUSTOMER only)' })
  async getMyFavorites(@CurrentUser('id') userId: string) {
    const favorites = await this.favoritesService.getMyFavorites(userId);
    return { success: true, data: favorites, message: 'Success' };
  }

  @Post('vendors/:vendorId')
  @ApiOperation({ summary: 'Toggle favorite vendor (CUSTOMER only)' })
  async toggleVendor(
    @CurrentUser('id') userId: string,
    @Param('vendorId') vendorId: string,
  ) {
    const result = await this.favoritesService.toggleVendor(userId, vendorId);
    const message = result.favorited ? 'Vendor added to favorites' : 'Vendor removed from favorites';
    return { success: true, data: result, message };
  }

  @Get('vendors')
  @ApiOperation({ summary: 'Get my favorite vendors (CUSTOMER only)' })
  async getMyVendorFavorites(@CurrentUser('id') userId: string) {
    const favorites = await this.favoritesService.getMyVendorFavorites(userId);
    return { success: true, data: favorites, message: 'Success' };
  }
}
