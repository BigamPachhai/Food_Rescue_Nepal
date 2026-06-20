import { IsString, IsOptional, IsInt, IsBoolean, IsDateString, Min, IsIn } from 'class-validator';

export class CreatePromoCodeDto {
  @IsString()
  code: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsIn(['PERCENT', 'FIXED'])
  discountType: 'PERCENT' | 'FIXED';

  @IsInt()
  @Min(1)
  discountValue: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  minOrderAmount?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  maxUses?: number;

  @IsOptional()
  @IsDateString()
  expiresAt?: string;

  @IsOptional()
  @IsString()
  vendorId?: string;
}

export class ValidatePromoDto {
  @IsString()
  code: string;

  @IsInt()
  @Min(0)
  orderAmount: number;
}
