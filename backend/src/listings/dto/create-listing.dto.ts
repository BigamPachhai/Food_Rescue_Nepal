import {
  IsString,
  IsOptional,
  IsEnum,
  IsInt,
  IsPositive,
  IsDateString,
  IsArray,
  Min,
  MinLength,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ListingCategory } from '@prisma/client';

export class CreateListingDto {
  @ApiProperty({ example: 'Momo Box (15 pcs)' })
  @IsString()
  @MinLength(3)
  @MaxLength(120)
  name: string;

  @ApiPropertyOptional({ example: 'Fresh steamed momos with tomato chutney' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiPropertyOptional({ enum: ListingCategory, default: ListingCategory.OTHER })
  @IsOptional()
  @IsEnum(ListingCategory)
  category?: ListingCategory;

  @ApiProperty({ example: 25000, description: 'Original price in paisa' })
  @IsInt()
  @IsPositive()
  originalPrice: number;

  @ApiProperty({ example: 10000, description: 'Discounted price in paisa' })
  @IsInt()
  @IsPositive()
  discountedPrice: number;

  @ApiProperty({ example: 10 })
  @IsInt()
  @Min(1)
  quantity: number;

  @ApiProperty({ example: '2024-01-01T10:00:00.000Z' })
  @IsDateString()
  pickupStart: string;

  @ApiProperty({ example: '2024-01-01T15:00:00.000Z' })
  @IsDateString()
  pickupEnd: string;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  imageUrls?: string[];

  @ApiPropertyOptional({ example: '2024-01-01T18:00:00.000Z' })
  @IsOptional()
  @IsDateString()
  expiryTime?: string;

  @ApiPropertyOptional({ example: 'Freshly baked, no preservatives' })
  @IsOptional()
  @IsString()
  conditionNotes?: string;

  @ApiPropertyOptional({ type: [String], example: ['VEGAN', 'HALAL'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  dietaryTags?: string[];
}
