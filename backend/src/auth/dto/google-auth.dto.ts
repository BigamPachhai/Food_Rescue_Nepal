import { IsString, IsNotEmpty, IsOptional, IsIn } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class GoogleAuthDto {
  @ApiProperty({ description: 'Firebase ID token obtained after Google Sign-In on the client' })
  @IsString()
  @IsNotEmpty()
  idToken: string;

  @ApiPropertyOptional({ description: 'Role to assign for new users (CUSTOMER or VENDOR). Omit to check if user exists without creating.', enum: ['CUSTOMER', 'VENDOR'] })
  @IsOptional()
  @IsString()
  @IsIn(['CUSTOMER', 'VENDOR'])
  role?: string;
}
