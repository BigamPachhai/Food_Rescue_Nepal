import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary, UploadApiResponse } from 'cloudinary';

@Injectable()
export class UploadService {
  private readonly logger = new Logger(UploadService.name);
  private isConfigured = false;

  constructor(private configService: ConfigService) {
    const cloudName = this.configService.get<string>('CLOUDINARY_CLOUD_NAME');
    const apiKey = this.configService.get<string>('CLOUDINARY_API_KEY');
    const apiSecret = this.configService.get<string>('CLOUDINARY_API_SECRET');

    if (cloudName && apiKey && apiSecret) {
      cloudinary.config({
        cloud_name: cloudName,
        api_key: apiKey,
        api_secret: apiSecret,
      });
      this.isConfigured = true;
      this.logger.log('Cloudinary configured');
    } else {
      this.logger.warn('Cloudinary not configured — image uploads will fail');
    }
  }

  async uploadImage(
    file: Express.Multer.File,
    folder: string = 'food-rescue-nepal',
  ): Promise<string> {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    if (!this.isConfigured) {
      throw new BadRequestException('Image upload service not configured');
    }

    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    if (!allowedMimeTypes.includes(file.mimetype)) {
      throw new BadRequestException('Only JPEG, PNG, WebP, and GIF images are allowed');
    }

    const maxSize = 10 * 1024 * 1024; // 10MB
    if (file.size > maxSize) {
      throw new BadRequestException('File size must be less than 10MB');
    }

    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder: `food-rescue-nepal/${folder}`,
          resource_type: 'image',
          transformation: [{ quality: 'auto', fetch_format: 'auto' }],
        },
        (error, result) => {
          if (error || !result) {
            this.logger.error('Cloudinary upload error:', error);
            reject(new BadRequestException('Failed to upload image'));
          } else {
            resolve(result.secure_url);
          }
        },
      );
      uploadStream.end(file.buffer);
    });
  }

  async deleteImage(publicId: string): Promise<void> {
    if (!this.isConfigured) return;
    try {
      await cloudinary.uploader.destroy(publicId);
    } catch (error) {
      this.logger.error('Cloudinary delete error:', error);
    }
  }
}
