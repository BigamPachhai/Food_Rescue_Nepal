import { Module } from '@nestjs/common';
import { ListingTemplatesService } from './listing-templates.service';
import { ListingTemplatesController } from './listing-templates.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [ListingTemplatesController],
  providers: [ListingTemplatesService],
  exports: [ListingTemplatesService],
})
export class ListingTemplatesModule {}
