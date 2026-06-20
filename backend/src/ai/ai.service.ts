import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private readonly apiKey: string;
  private readonly model = 'mistral-small-2603';
  private readonly baseUrl = 'https://api.mistral.ai/v1/chat/completions';

  constructor(private readonly config: ConfigService) {
    this.apiKey = this.config.get<string>('MISTRAL_API_KEY', '');
  }

  private async callMistral(systemPrompt: string, userPrompt: string): Promise<string> {
    if (!this.apiKey) {
      throw new ServiceUnavailableException('AI service is not configured');
    }
    const res = await fetch(this.baseUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify({
        model: this.model,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        max_tokens: 512,
        temperature: 0.7,
      }),
    });

    if (!res.ok) {
      const errBody = await res.text();
      this.logger.error(`Mistral API error: ${res.status} ${res.statusText} — ${errBody}`);
      throw new ServiceUnavailableException(`AI service error: ${res.status} ${res.statusText}`);
    }

    const data = await res.json() as any;
    return data.choices?.[0]?.message?.content ?? '';
  }

  async chat(message: string, history: { role: string; content: string }[] = []): Promise<string> {
    if (!this.apiKey) throw new ServiceUnavailableException('AI service is not configured');

    const res = await fetch(this.baseUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify({
        model: this.model,
        messages: [
          { role: 'system', content: 'You are a helpful assistant for Food Rescue Nepal, a platform that connects surplus food vendors with customers to reduce food waste in Nepal. Help users with food rescue, orders, vendors, and sustainability tips. Keep replies concise and friendly.' },
          ...history,
          { role: 'user', content: message },
        ],
        max_tokens: 400,
        temperature: 0.7,
      }),
    });

    if (!res.ok) {
      const errBody = await res.text();
      this.logger.error(`Mistral chat error: ${res.status} ${res.statusText} — ${errBody}`);
      throw new ServiceUnavailableException(`AI service error: ${res.status} ${res.statusText}`);
    }
    const data = await res.json() as any;
    return data.choices?.[0]?.message?.content ?? '';
  }

  async generateDescription(name: string, category: string, price: number): Promise<string> {
    return this.callMistral(
      'You are a food copywriter for a Nepali food rescue app. Write short, enticing, honest food listing descriptions in 2-3 sentences.',
      `Write a description for: "${name}" (Category: ${category}, Price: NPR ${price}). Emphasize freshness, value, and sustainability.`,
    );
  }

  async suggestPrice(name: string, originalPrice: number, quantityLeft: number): Promise<string> {
    return this.callMistral(
      'You are a pricing advisor for a food rescue marketplace in Nepal. Suggest rescue prices to sell surplus food quickly while giving vendors fair return.',
      `Item: "${name}". Original price: NPR ${originalPrice}. Quantity remaining: ${quantityLeft}. Suggest a rescue price range and a one-line justification.`,
    );
  }

  async suggestRecipes(ingredients: string[]): Promise<string> {
    return this.callMistral(
      'You are a creative Nepali recipe assistant. Suggest simple recipes using available ingredients that help reduce food waste.',
      `Suggest 2-3 quick recipes using these rescued ingredients: ${ingredients.join(', ')}. Give each recipe a name and 3-5 brief steps.`,
    );
  }

  async analyzeSentiment(reviews: string[]): Promise<string> {
    return this.callMistral(
      'You are a sentiment analysis assistant for a food vendor analytics platform.',
      `Analyze the sentiment of these customer reviews and give a brief summary with key positives and areas to improve:\n${reviews.map((r, i) => `${i + 1}. "${r}"`).join('\n')}`,
    );
  }

  async predictDemand(itemName: string, weeklySales: number[]): Promise<string> {
    return this.callMistral(
      'You are a demand forecasting assistant for a food rescue marketplace.',
      `Item: "${itemName}". Weekly sales over last ${weeklySales.length} weeks: ${weeklySales.join(', ')}. Predict demand for next week and suggest optimal listing quantity.`,
    );
  }
}
