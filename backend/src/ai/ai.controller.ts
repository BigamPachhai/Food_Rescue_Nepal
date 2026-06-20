import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { IsArray, IsNumber, IsOptional, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { AiService } from './ai.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';

class HistoryItemDto {
  @IsString() role: string;
  @IsString() content: string;
}

class ChatDto {
  @IsString() message: string;
  @IsOptional() @IsArray() @ValidateNested({ each: true }) @Type(() => HistoryItemDto)
  history?: HistoryItemDto[];
}

class DescriptionDto {
  @IsString() name: string;
  @IsString() category: string;
  @IsNumber() price: number;
}

class PricingDto {
  @IsString() name: string;
  @IsNumber() originalPrice: number;
  @IsNumber() quantityLeft: number;
}

class RecipesDto {
  @IsArray() @IsString({ each: true }) ingredients: string[];
}

class SentimentDto {
  @IsArray() @IsString({ each: true }) reviews: string[];
}

class DemandDto {
  @IsString() itemName: string;
  @IsArray() @IsNumber({}, { each: true }) weeklySales: number[];
}

@Controller('ai')
@UseGuards(JwtAuthGuard)
export class AiController {
  constructor(private readonly ai: AiService) {}

  @Post('chat')
  chat(@Body() dto: ChatDto) {
    return this.ai.chat(dto.message, dto.history ?? []).then(reply => ({ reply }));
  }

  @Post('description')
  description(@Body() dto: DescriptionDto) {
    return this.ai.generateDescription(dto.name, dto.category, dto.price).then(result => ({ result }));
  }

  @Post('pricing')
  pricing(@Body() dto: PricingDto) {
    return this.ai.suggestPrice(dto.name, dto.originalPrice, dto.quantityLeft).then(result => ({ result }));
  }

  @Post('recipes')
  recipes(@Body() dto: RecipesDto) {
    return this.ai.suggestRecipes(dto.ingredients).then(result => ({ result }));
  }

  @Post('sentiment')
  sentiment(@Body() dto: SentimentDto) {
    return this.ai.analyzeSentiment(dto.reviews).then(result => ({ result }));
  }

  @Post('demand')
  demand(@Body() dto: DemandDto) {
    return this.ai.predictDemand(dto.itemName, dto.weeklySales).then(result => ({ result }));
  }
}
