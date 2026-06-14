import { IsOptional, IsString, IsPhoneNumber } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateProfileDto {
  @ApiPropertyOptional({ example: 'Priya Shrestha' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: '+9779800000000' })
  @IsOptional()
  @IsString()
  phone?: string;
}
