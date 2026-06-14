import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  DefaultValuePipe,
  ParseIntPipe,
} from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('Notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  @ApiOperation({ summary: 'Get paginated notifications (unread first)' })
  async getNotifications(
    @CurrentUser('id') userId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    const result = await this.notificationsService.getNotifications(userId, page, limit);
    return { success: true, data: result, message: 'Success' };
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Get unread notification count' })
  async getUnreadCount(@CurrentUser('id') userId: string) {
    const result = await this.notificationsService.getUnreadCount(userId);
    return { success: true, data: result, message: 'Success' };
  }

  @Post('fcm-token')
  @ApiOperation({ summary: 'Register FCM device token' })
  async registerFcmToken(
    @CurrentUser('id') userId: string,
    @Body('fcmToken') fcmToken: string,
  ) {
    const result = await this.notificationsService.registerFcmToken(userId, fcmToken);
    return { success: true, data: result, message: 'FCM token registered' };
  }

  @Patch('read-all')
  @ApiOperation({ summary: 'Mark all notifications as read' })
  async markAllRead(@CurrentUser('id') userId: string) {
    const result = await this.notificationsService.markAllRead(userId);
    return { success: true, data: result, message: 'All notifications marked as read' };
  }

  @Patch(':id/read')
  @ApiOperation({ summary: 'Mark a notification as read' })
  async markRead(@Param('id') id: string, @CurrentUser('id') userId: string) {
    const result = await this.notificationsService.markRead(id, userId);
    return { success: true, data: result, message: 'Notification marked as read' };
  }

  @Delete('all')
  @ApiOperation({ summary: 'Delete all notifications' })
  async deleteAll(@CurrentUser('id') userId: string) {
    const result = await this.notificationsService.deleteAll(userId);
    return { success: true, data: result, message: 'All notifications deleted' };
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a notification' })
  async deleteOne(@Param('id') id: string, @CurrentUser('id') userId: string) {
    const result = await this.notificationsService.deleteOne(id, userId);
    return { success: true, data: result, message: 'Notification deleted' };
  }
}
