import { IsString } from 'class-validator';

export class JoinWaitlistDto {
  @IsString()
  listingId: string;
}
