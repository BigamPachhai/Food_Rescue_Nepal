import {
  Controller,
  Post,
  Body,
  Res,
  Req,
  Get,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { Response, Request } from 'express';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from '@nestjs/swagger';

const REFRESH_COOKIE_OPTIONS = {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'lax' as const,
  maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days in ms
  path: '/',
};

@ApiTags('Auth')
@Controller('auth')
@Throttle({ short: { ttl: 60000, limit: 5 }, medium: { ttl: 3600000, limit: 20 } })
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @ApiOperation({ summary: 'Register a new user (CUSTOMER or VENDOR)' })
  async register(@Body() dto: RegisterDto, @Res({ passthrough: true }) res: Response) {
    const result = await this.authService.register(dto);
    res.cookie('refreshToken', result.refreshToken, REFRESH_COOKIE_OPTIONS);
    return {
      success: true,
      data: { user: result.user, accessToken: result.accessToken, refreshToken: result.refreshToken },
      message: 'Registration successful',
    };
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login with email and password' })
  async login(@Body() dto: LoginDto, @Res({ passthrough: true }) res: Response) {
    const result = await this.authService.login(dto);
    res.cookie('refreshToken', result.refreshToken, REFRESH_COOKIE_OPTIONS);
    return {
      success: true,
      data: { user: result.user, accessToken: result.accessToken, refreshToken: result.refreshToken },
      message: 'Login successful',
    };
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Refresh access token (cookie for web, body for mobile)' })
  async refresh(
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
    @Body() body: { refreshToken?: string },
  ) {
    const refreshToken = req.cookies?.refreshToken ?? body?.refreshToken;
    if (!refreshToken) {
      return {
        success: false,
        error: { code: 'UNAUTHORIZED', message: 'Refresh token not found' },
      };
    }
    const tokens = await this.authService.refresh(refreshToken);
    res.cookie('refreshToken', tokens.refreshToken, REFRESH_COOKIE_OPTIONS);
    return {
      success: true,
      data: { accessToken: tokens.accessToken, refreshToken: tokens.refreshToken },
      message: 'Token refreshed',
    };
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Logout - clears refresh token cookie' })
  async logout(
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
    @Body() body: { refreshToken?: string },
  ) {
    const refreshToken = req.cookies?.refreshToken ?? body?.refreshToken;
    await this.authService.logout(refreshToken);
    res.clearCookie('refreshToken', { path: '/' });
    return {
      success: true,
      data: null,
      message: 'Logged out successfully',
    };
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current user info' })
  async getMe(@CurrentUser('id') userId: string) {
    const user = await this.authService.getMe(userId);
    return {
      success: true,
      data: user,
      message: 'Success',
    };
  }

  @Post('google')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Sign in or register with Google (Firebase ID token)' })
  async googleSignIn(@Body() dto: GoogleAuthDto, @Res({ passthrough: true }) res: Response) {
    const result = await this.authService.googleSignIn(dto.idToken, dto.role);
    if (result.isNewUser && !result.accessToken) {
      // New user who hasn't selected a role yet — don't set a cookie
      return { success: true, data: { isNewUser: true }, message: 'Role selection required' };
    }
    res.cookie('refreshToken', result.refreshToken, REFRESH_COOKIE_OPTIONS);
    return {
      success: true,
      data: { isNewUser: result.isNewUser, user: result.user, accessToken: result.accessToken, refreshToken: result.refreshToken },
      message: 'Google sign-in successful',
    };
  }

  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Request a password reset OTP' })
  async forgotPassword(@Body() body: { email: string }) {
    if (!body.email) throw new (require('@nestjs/common').BadRequestException)('Email is required');
    const result = await this.authService.forgotPassword(body.email);
    return {
      success: true,
      data: { otp: result.otp, isDevMode: result.isDevMode },
      message: 'OTP sent to your email',
    };
  }

  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reset password using OTP' })
  async resetPassword(@Body() body: { email: string; otp: string; newPassword: string }) {
    await this.authService.resetPassword(body.email, body.otp, body.newPassword);
    return {
      success: true,
      data: null,
      message: 'Password reset successfully. Please login with your new password.',
    };
  }
}
