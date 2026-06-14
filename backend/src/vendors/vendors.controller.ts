import {
  Controller,
  Get,
  Patch,
  Post,
  Param,
  Body,
  Query,
  UseGuards,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { VendorsService } from './vendors.service';
import { UpdateVendorDto } from './dto/update-vendor.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UploadService } from '../upload/upload.service';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiConsumes,
} from '@nestjs/swagger';

@ApiTags('Vendors')
@Controller('vendors')
export class VendorsController {
  constructor(
    private readonly vendorsService: VendorsService,
    private readonly uploadService: UploadService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'Get all approved vendors (public)' })
  async findAll(
    @Query('lat') lat?: string,
    @Query('lng') lng?: string,
  ) {
    const latNum = lat ? parseFloat(lat) : undefined;
    const lngNum = lng ? parseFloat(lng) : undefined;
    const vendors = await this.vendorsService.findAll(latNum, lngNum);
    return { success: true, data: vendors, message: 'Success' };
  }

  @Get('stats')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR' as any)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get vendor dashboard stats' })
  async getStats(@CurrentUser('id') userId: string) {
    const stats = await this.vendorsService.getStats(userId);
    return { success: true, data: stats, message: 'Success' };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get vendor detail with listings and reviews (public)' })
  async findOne(@Param('id') id: string) {
    const vendor = await this.vendorsService.findOne(id);
    return { success: true, data: vendor, message: 'Success' };
  }

  @Patch('profile')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR' as any)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update vendor profile' })
  async updateProfile(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateVendorDto,
  ) {
    const vendor = await this.vendorsService.updateProfile(userId, dto);
    return { success: true, data: vendor, message: 'Vendor profile updated' };
  }

  @Post('logo')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR' as any)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Upload vendor logo to Cloudinary' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  async uploadLogo(
    @CurrentUser('id') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    const url = await this.uploadService.uploadImage(file, 'logos');
    const vendor = await this.vendorsService.updateLogo(userId, url);
    return { success: true, data: vendor, message: 'Logo updated' };
  }
}
