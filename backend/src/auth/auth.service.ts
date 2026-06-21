import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
  ConflictException,
  ServiceUnavailableException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { Role } from '@prisma/client';
import * as admin from 'firebase-admin';
import { MailService } from '../mail/mail.service';

const BCRYPT_ROUNDS = 12;

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
    private mailService: MailService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    if (dto.role === 'VENDOR') {
      if (!dto.businessName || !dto.businessType || !dto.address || dto.lat == null || dto.lng == null) {
        throw new BadRequestException(
          'VENDOR registration requires businessName, businessType, address, lat, lng',
        );
      }
    }

    const passwordHash = dto.password
      ? await bcrypt.hash(dto.password, BCRYPT_ROUNDS)
      : null;

    const result = await this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          name: dto.name,
          email: dto.email,
          phone: dto.phone,
          passwordHash,
          role: dto.role as Role,
        },
      });

      if (dto.role === 'VENDOR') {
        await tx.vendor.create({
          data: {
            userId: user.id,
            businessName: dto.businessName!,
            businessType: dto.businessType!,
            address: dto.address!,
            lat: dto.lat!,
            lng: dto.lng!,
          },
        });
      }

      return user;
    });

    const tokens = await this.generateTokens(result.id, result.email, result.role);

    return {
      user: {
        id: result.id,
        name: result.name,
        email: result.email,
        phone: result.phone,
        role: result.role,
        avatarUrl: result.avatarUrl,
        isActive: result.isActive,
        createdAt: result.createdAt,
        vendor: null,
      },
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    };
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
      include: { vendor: true },
    });

    if (!user || user.deletedAt) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Account is banned');
    }

    if (!user.passwordHash) {
      throw new UnauthorizedException('This account uses Google Sign-In. Please sign in with Google.');
    }

    const passwordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!passwordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const tokens = await this.generateTokens(user.id, user.email, user.role);

    return {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        avatarUrl: user.avatarUrl,
        isActive: user.isActive,
        createdAt: user.createdAt,
        vendor: user.vendor
          ? { id: user.vendor.id, status: user.vendor.status }
          : null,
      },
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    };
  }

  async refresh(refreshToken: string) {
    const stored = await this.prisma.refreshToken.findUnique({
      where: { token: refreshToken },
      include: { user: true },
    });

    if (!stored || stored.expiresAt < new Date()) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    if (!stored.user.isActive || stored.user.deletedAt) {
      throw new UnauthorizedException('User account is inactive');
    }

    // Rotate refresh token
    await this.prisma.refreshToken.delete({ where: { token: refreshToken } });

    const tokens = await this.generateTokens(
      stored.user.id,
      stored.user.email,
      stored.user.role,
    );

    return tokens;
  }

  async logout(refreshToken: string) {
    if (refreshToken) {
      await this.prisma.refreshToken.deleteMany({ where: { token: refreshToken } });
    }
  }

  async forgotPassword(email: string): Promise<{ otp: string; isDevMode: boolean }> {
    const user = await this.prisma.user.findUnique({ where: { email } });
    const isDevMode = this.configService.get<string>('NODE_ENV') !== 'production';

    if (!user || user.deletedAt) {
      // Don't reveal whether email exists; still return success shape
      return { otp: '', isDevMode };
    }

    await this.prisma.passwordResetOtp.deleteMany({ where: { email } });

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    await this.prisma.passwordResetOtp.create({ data: { email, otp, expiresAt } });

    // Fire-and-forget — OTP is already persisted; don't block the response on SMTP
    this.mailService.sendPasswordResetOtp(email, otp).catch((err) => {
      this.logger.error(`Failed to send OTP email to ${email}: ${err}`);
    });

    return { otp: isDevMode ? otp : '', isDevMode };
  }

  async resetPassword(email: string, otp: string, newPassword: string): Promise<void> {
    const record = await this.prisma.passwordResetOtp.findFirst({
      where: { email, otp },
    });

    if (!record || record.expiresAt < new Date()) {
      throw new BadRequestException('Invalid or expired OTP. Please request a new one.');
    }

    const passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);

    await this.prisma.$transaction([
      this.prisma.user.update({ where: { email }, data: { passwordHash } }),
      this.prisma.passwordResetOtp.deleteMany({ where: { email } }),
      this.prisma.refreshToken.deleteMany({ where: { user: { email } } }),
    ]);
  }

  async googleSignIn(idToken: string, role?: string, vendorFields?: { businessName?: string; businessType?: string; address?: string; lat?: number; lng?: number; phone?: string }) {
    if (admin.apps.length === 0) {
      throw new BadRequestException('Google Sign-In is not configured on the server');
    }

    let decoded: admin.auth.DecodedIdToken;
    try {
      decoded = await admin.auth().verifyIdToken(idToken);
    } catch {
      throw new UnauthorizedException('Invalid Google ID token');
    }

    const { uid: googleId, email, name, picture } = decoded;

    if (!email) {
      throw new BadRequestException('Google account must have an email address');
    }

    // Find existing user by googleId or email
    let user = await this.prisma.user.findFirst({
      where: { OR: [{ googleId }, { email }] },
    });

    if (user) {
      if (user.deletedAt) throw new UnauthorizedException('Account has been deleted');
      if (!user.isActive) throw new UnauthorizedException('Account is banned');
      // Link googleId if the user signed up via email previously
      if (!user.googleId) {
        user = await this.prisma.user.update({
          where: { id: user.id },
          data: { googleId, avatarUrl: user.avatarUrl ?? picture ?? null },
        });
      }

      const tokens = await this.generateTokens(user.id, user.email, user.role);
      return {
        isNewUser: false,
        user: { id: user.id, name: user.name, email: user.email, phone: user.phone, role: user.role, avatarUrl: user.avatarUrl, isActive: user.isActive, createdAt: user.createdAt, vendor: null },
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      };
    }

    // New user — require role selection before creating account
    if (!role) {
      return { isNewUser: true, user: null, accessToken: null, refreshToken: null };
    }

    if (role === 'VENDOR') {
      const { businessName, businessType, address, lat, lng, phone } = vendorFields ?? {};
      if (!businessName || !businessType || !address || lat == null || lng == null) {
        throw new BadRequestException('VENDOR registration requires businessName, businessType, address, lat, lng');
      }
      const newUser = await this.prisma.$transaction(async (tx) => {
        const user = await tx.user.create({
          data: {
            name: name ?? email.split('@')[0],
            email,
            googleId,
            avatarUrl: picture ?? null,
            role: role as Role,
            phone: phone ?? null,
          },
        });
        await tx.vendor.create({
          data: { userId: user.id, businessName, businessType, address, lat, lng },
        });
        return user;
      });
      const tokens = await this.generateTokens(newUser.id, newUser.email, newUser.role);
      return {
        isNewUser: true,
        user: { id: newUser.id, name: newUser.name, email: newUser.email, phone: newUser.phone, role: newUser.role, avatarUrl: newUser.avatarUrl, isActive: newUser.isActive, createdAt: newUser.createdAt, vendor: null },
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      };
    }

    const newUser = await this.prisma.user.create({
      data: {
        name: name ?? email.split('@')[0],
        email,
        googleId,
        avatarUrl: picture ?? null,
        role: role as Role,
      },
    });

    const tokens = await this.generateTokens(newUser.id, newUser.email, newUser.role);
    return {
      isNewUser: true,
      user: { id: newUser.id, name: newUser.name, email: newUser.email, phone: newUser.phone, role: newUser.role, avatarUrl: newUser.avatarUrl, isActive: newUser.isActive, createdAt: newUser.createdAt, vendor: null },
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    };
  }

  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        avatarUrl: true,
        isActive: true,
        createdAt: true,
        vendor: {
          select: {
            id: true,
            businessName: true,
            businessType: true,
            address: true,
            lat: true,
            lng: true,
            logoUrl: true,
            description: true,
            status: true,
            avgRating: true,
            totalReviews: true,
          },
        },
      },
    });

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    return user;
  }

  private async generateTokens(userId: string, email: string, role: string) {
    const payload = { sub: userId, email, role };

    const accessToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('JWT_ACCESS_SECRET'),
      expiresIn: this.configService.get<string>('JWT_ACCESS_EXPIRES_IN') || '15m',
    });

    const rawRefreshToken = crypto.randomBytes(64).toString('hex');

    const refreshExpiresIn = this.configService.get<string>('JWT_REFRESH_EXPIRES_IN') || '7d';
    const expiresAt = new Date();
    const match = refreshExpiresIn.match(/^(\d+)([smhd])$/);
    const multipliers: Record<string, number> = { s: 1000, m: 60000, h: 3600000, d: 86400000 };
    const ttlMs = match ? parseInt(match[1]) * (multipliers[match[2]] ?? 86400000) : 7 * 86400000;
    expiresAt.setTime(expiresAt.getTime() + ttlMs);

    await this.prisma.refreshToken.create({
      data: {
        token: rawRefreshToken,
        userId,
        expiresAt,
      },
    });

    return { accessToken, refreshToken: rawRefreshToken };
  }
}
