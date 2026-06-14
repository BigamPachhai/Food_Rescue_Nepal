import {
  Controller,
  Patch,
  Post,
  Delete,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { UsersService } from './users.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UploadService } from '../upload/upload.service';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiConsumes } from '@nestjs/swagger';
import { IsString } from 'class-validator';

class UpdateFcmTokenDto {
  @IsString()
  fcmToken: string;
}

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly uploadService: UploadService,
  ) {}

  @Patch('profile')
  @ApiOperation({ summary: 'Update user profile (name, phone)' })
  async updateProfile(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateProfileDto,
  ) {
    const user = await this.usersService.updateProfile(userId, dto);
    return { success: true, data: user, message: 'Profile updated' };
  }

  @Post('avatar')
  @ApiOperation({ summary: 'Upload avatar image to Cloudinary' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  async uploadAvatar(
    @CurrentUser('id') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    const url = await this.uploadService.uploadImage(file, 'avatars');
    const user = await this.usersService.updateAvatar(userId, url);
    return { success: true, data: user, message: 'Avatar updated' };
  }

  @Patch('fcm-token')
  @ApiOperation({ summary: 'Update FCM push notification token' })
  async updateFcmToken(
    @CurrentUser('id') userId: string,
    @Body() body: UpdateFcmTokenDto,
  ) {
    const result = await this.usersService.updateFcmToken(userId, body.fcmToken);
    return { success: true, data: result, message: 'FCM token updated' };
  }

  @Delete('account')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Soft delete account' })
  async deleteAccount(@CurrentUser('id') userId: string) {
    const result = await this.usersService.deleteAccount(userId);
    return { success: true, data: result, message: 'Account deleted' };
  }
}
