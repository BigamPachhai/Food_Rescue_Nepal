import { Controller, Post, Get, Body, UseGuards } from '@nestjs/common';
import { TwoFactorService } from './two-factor.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { IsString } from 'class-validator';

class TokenDto {
  @IsString()
  token: string;
}

@UseGuards(JwtAuthGuard)
@Controller('2fa')
export class TwoFactorController {
  constructor(private readonly twoFactorService: TwoFactorService) {}

  @Get('status')
  getStatus(@CurrentUser() user: any) {
    return this.twoFactorService.getStatus(user.id);
  }

  @Post('setup')
  setup(@CurrentUser() user: any) {
    return this.twoFactorService.setup(user.id);
  }

  @Post('enable')
  enable(@CurrentUser() user: any, @Body() dto: TokenDto) {
    return this.twoFactorService.enable(user.id, dto.token);
  }

  @Post('disable')
  disable(@CurrentUser() user: any, @Body() dto: TokenDto) {
    return this.twoFactorService.disable(user.id, dto.token);
  }
}
