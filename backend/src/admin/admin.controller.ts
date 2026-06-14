import {
  Controller,
  Get,
  Patch,
  Param,
  Query,
  UseGuards,
  DefaultValuePipe,
  ParseIntPipe,
} from '@nestjs/common';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { VendorStatus, OrderStatus } from '@prisma/client';

@ApiTags('Admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN' as any)
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('stats')
  @ApiOperation({ summary: 'Get platform statistics (ADMIN only)' })
  async getStats() {
    const stats = await this.adminService.getStats();
    return { success: true, data: stats, message: 'Success' };
  }

  // Users
  @Get('users')
  @ApiOperation({ summary: 'Get all users paginated (ADMIN only)' })
  async getUsers(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('role') role?: string,
    @Query('isActive') isActive?: string,
    @Query('search') search?: string,
  ) {
    const isActiveBool = isActive === 'true' ? true : isActive === 'false' ? false : undefined;
    const result = await this.adminService.getUsers(page, limit, role, isActiveBool, search);
    return { success: true, data: result, message: 'Success' };
  }

  @Get('users/:id')
  @ApiOperation({ summary: 'Get user by ID (ADMIN only)' })
  async getUserById(@Param('id') id: string) {
    const user = await this.adminService.getUserById(id);
    return { success: true, data: user, message: 'Success' };
  }

  @Patch('users/:id/ban')
  @ApiOperation({ summary: 'Toggle user ban status (ADMIN only)' })
  async toggleBan(@Param('id') id: string) {
    const user = await this.adminService.toggleUserBan(id);
    return { success: true, data: user, message: 'User ban status toggled' };
  }

  // Vendors
  @Get('vendors')
  @ApiOperation({ summary: 'Get all vendors paginated (ADMIN only)' })
  async getVendors(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('status') status?: VendorStatus,
    @Query('search') search?: string,
  ) {
    const result = await this.adminService.getVendors(page, limit, status, search);
    return { success: true, data: result, message: 'Success' };
  }

  @Get('vendors/:id')
  @ApiOperation({ summary: 'Get vendor detail (ADMIN only)' })
  async getVendorById(@Param('id') id: string) {
    const vendor = await this.adminService.getVendorById(id);
    return { success: true, data: vendor, message: 'Success' };
  }

  @Patch('vendors/:id/approve')
  @ApiOperation({ summary: 'Approve a vendor (ADMIN only)' })
  async approveVendor(@Param('id') id: string) {
    const vendor = await this.adminService.approveVendor(id);
    return { success: true, data: vendor, message: 'Vendor approved' };
  }

  @Patch('vendors/:id/suspend')
  @ApiOperation({ summary: 'Suspend a vendor (ADMIN only)' })
  async suspendVendor(@Param('id') id: string) {
    const vendor = await this.adminService.suspendVendor(id);
    return { success: true, data: vendor, message: 'Vendor suspended' };
  }

  // Listings
  @Get('listings')
  @ApiOperation({ summary: 'Get all listings (ADMIN only)' })
  async getListings(
    @Query('isActive') isActive?: string,
    @Query('vendorId') vendorId?: string,
    @Query('category') category?: string,
  ) {
    const isActiveBool = isActive === 'true' ? true : isActive === 'false' ? false : undefined;
    const listings = await this.adminService.getListings(isActiveBool, vendorId, category);
    return { success: true, data: listings, message: 'Success' };
  }

  @Patch('listings/:id/deactivate')
  @ApiOperation({ summary: 'Force deactivate a listing (ADMIN only)' })
  async deactivateListing(@Param('id') id: string) {
    const listing = await this.adminService.deactivateListing(id);
    return { success: true, data: listing, message: 'Listing deactivated' };
  }

  // Orders
  @Get('orders')
  @ApiOperation({ summary: 'Get all orders paginated (ADMIN only)' })
  async getOrders(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('status') status?: OrderStatus,
    @Query('vendorId') vendorId?: string,
    @Query('customerId') customerId?: string,
  ) {
    const result = await this.adminService.getOrders(page, limit, status, vendorId, customerId);
    return { success: true, data: result, message: 'Success' };
  }

  @Get('orders/:id')
  @ApiOperation({ summary: 'Get any order detail (ADMIN only)' })
  async getOrderById(@Param('id') id: string) {
    const order = await this.adminService.getOrderById(id);
    return { success: true, data: order, message: 'Success' };
  }
}
