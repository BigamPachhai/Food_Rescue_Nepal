import {
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Role } from '@prisma/client';

export class RegisterDto {
  @ApiProperty({ example: 'Priya Shrestha' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  email: string;

  @ApiPropertyOptional({ example: 'StrongPass@123', minLength: 8 })
  @IsOptional()
  @IsString()
  @MinLength(8)
  password?: string;

  @ApiProperty({ enum: ['CUSTOMER', 'VENDOR'] })
  @IsEnum(['CUSTOMER', 'VENDOR'])
  role: 'CUSTOMER' | 'VENDOR';

  @ApiPropertyOptional({ example: '+9779800000000' })
  @IsOptional()
  @IsString()
  phone?: string;

  // Vendor-specific fields
  @ApiPropertyOptional({ example: 'Green Bites Cafe' })
  @IsOptional()
  @IsString()
  businessName?: string;

  @ApiPropertyOptional({ example: 'Cafe' })
  @IsOptional()
  @IsString()
  businessType?: string;

  @ApiPropertyOptional({ example: 'Thamel, Kathmandu' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: 27.7152 })
  @IsOptional()
  @IsNumber()
  lat?: number;

  @ApiPropertyOptional({ example: 85.3123 })
  @IsOptional()
  @IsNumber()
  lng?: number;
}
