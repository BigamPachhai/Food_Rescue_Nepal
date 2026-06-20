import { IsString, IsInt, IsDateString, Min } from 'class-validator';

export class CreateFlashSaleDto {
  @IsString()
  listingId: string;

  @IsInt()
  @Min(1)
  salePrice: number;

  @IsDateString()
  startsAt: string;

  @IsDateString()
  endsAt: string;
}
