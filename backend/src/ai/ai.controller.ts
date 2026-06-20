import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { AiService } from './ai.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';

class ChatDto {
  message: string;
  history?: { role: string; content: string }[];
}
class DescriptionDto { name: string; category: string; price: number; }
class PricingDto { name: string; originalPrice: number; quantityLeft: number; }
class RecipesDto { ingredients: string[]; }
class SentimentDto { reviews: string[]; }
class DemandDto { itemName: string; weeklySales: number[]; }

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
