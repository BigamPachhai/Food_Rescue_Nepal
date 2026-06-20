import { Controller, Post, Get, Body, Param, UseGuards } from '@nestjs/common';
import { ChatService, SendMessageDto } from './chat.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post(':orderId')
  send(
    @Param('orderId') orderId: string,
    @CurrentUser() user: any,
    @Body() dto: SendMessageDto,
  ) {
    return this.chatService.sendMessage(orderId, user.id, dto.body);
  }

  @Get(':orderId')
  getMessages(@Param('orderId') orderId: string, @CurrentUser() user: any) {
    return this.chatService.getMessages(orderId, user.id);
  }

  @Get('unread/count')
  unreadCount(@CurrentUser() user: any) {
    return this.chatService.getUnreadCount(user.id);
  }
}
