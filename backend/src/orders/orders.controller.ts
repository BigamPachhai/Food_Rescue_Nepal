import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  DefaultValuePipe,
  ParseIntPipe,
} from '@nestjs/common';
import { OrdersService, BulkAcceptDto } from './orders.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('Orders')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles('CUSTOMER' as any)
  @ApiOperation({ summary: 'Place an order (CUSTOMER only)' })
  async create(@CurrentUser('id') userId: string, @Body() dto: CreateOrderDto) {
    const order = await this.ordersService.create(userId, dto);
    return { success: true, data: order, message: 'Order placed' };
  }

  @Get('my')
  @UseGuards(RolesGuard)
  @Roles('CUSTOMER' as any)
  @ApiOperation({ summary: 'Get my orders (CUSTOMER only)' })
  async getMyOrders(
    @CurrentUser('id') userId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    const result = await this.ordersService.getCustomerOrders(userId, page, limit);
    return { success: true, data: result, message: 'Success' };
  }

  @Get('vendor')
  @UseGuards(RolesGuard)
  @Roles('VENDOR' as any)
  @ApiOperation({ summary: 'Get orders for vendor (VENDOR only)' })
  async getVendorOrders(
    @CurrentUser('id') userId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    const result = await this.ordersService.getVendorOrders(userId, page, limit);
    return { success: true, data: result, message: 'Success' };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get order by ID (own order or admin)' })
  async findOne(
    @Param('id') id: string,
    @CurrentUser() user: any,
  ) {
    const order = await this.ordersService.findOne(id, user.id, user.role);
    return { success: true, data: order, message: 'Success' };
  }

  @Patch(':id/accept')
  @UseGuards(RolesGuard)
  @Roles('VENDOR' as any)
  @ApiOperation({ summary: 'Accept reservation - PENDING → ACCEPTED (VENDOR only)' })
  async accept(@Param('id') id: string, @CurrentUser('id') userId: string) {
    const order = await this.ordersService.accept(id, userId);
    return { success: true, data: order, message: 'Order accepted' };
  }

  @Patch(':id/ready')
  @UseGuards(RolesGuard)
  @Roles('VENDOR' as any)
  @ApiOperation({ summary: 'Mark order ready - ACCEPTED → READY (VENDOR only)' })
  async markReady(@Param('id') id: string, @CurrentUser('id') userId: string) {
    const order = await this.ordersService.markReady(id, userId);
    return { success: true, data: order, message: 'Order marked as ready' };
  }

  @Patch(':id/pickup')
  @UseGuards(RolesGuard)
  @Roles('VENDOR' as any)
  @ApiOperation({ summary: 'Complete order - READY → COMPLETED, verify pickup code (VENDOR only)' })
  async pickup(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body('pickupCode') pickupCode: string,
  ) {
    const order = await this.ordersService.pickup(id, userId, pickupCode);
    return { success: true, data: order, message: 'Order completed' };
  }

  @Patch(':id/reject')
  @UseGuards(RolesGuard)
  @Roles('VENDOR' as any)
  @ApiOperation({ summary: 'Reject reservation - PENDING → REJECTED (VENDOR only)' })
  async reject(@Param('id') id: string, @CurrentUser('id') userId: string) {
    const order = await this.ordersService.reject(id, userId);
    return { success: true, data: order, message: 'Reservation rejected' };
  }

  @Patch(':id/expire')
  @UseGuards(RolesGuard)
  @Roles('VENDOR' as any)
  @ApiOperation({ summary: 'Expire reservation - READY → EXPIRED (VENDOR only)' })
  async expire(@Param('id') id: string, @CurrentUser('id') userId: string) {
    const order = await this.ordersService.expire(id, userId);
    return { success: true, data: order, message: 'Reservation marked as expired' };
  }

  @Patch(':id/cancel')
  @UseGuards(RolesGuard)
  @Roles('CUSTOMER' as any)
  @ApiOperation({ summary: 'Cancel reservation - PENDING only within 10 min (CUSTOMER only)' })
  async cancel(@Param('id') id: string, @CurrentUser('id') userId: string) {
    const order = await this.ordersService.cancel(id, userId);
    return { success: true, data: order, message: 'Reservation cancelled' };
  }

  @Post('bulk-accept')
  @UseGuards(RolesGuard)
  @Roles('VENDOR' as any)
  @ApiOperation({ summary: 'Bulk accept multiple pending orders (VENDOR only)' })
  async bulkAccept(@CurrentUser('id') userId: string, @Body() dto: BulkAcceptDto) {
    const results = await this.ordersService.bulkAccept(userId, dto);
    return { success: true, data: results, message: 'Bulk accept processed' };
  }
}
