import { IsInt, IsString, Min } from 'class-validator';

export class RedeemPointsDto {
  @IsInt()
  @Min(1)
  points: number;

  @IsString()
  orderId: string;
}
