import { PrismaClient, Role, VendorStatus, ListingCategory } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  const BCRYPT_ROUNDS = 12;

  // 1. Admin
  const adminEmail = process.env.ADMIN_SEED_EMAIL || 'admin@foodrescuenepal.com';
  const adminPassword = process.env.ADMIN_SEED_PASSWORD || 'Admin@12345!';
  const adminHash = await bcrypt.hash(adminPassword, BCRYPT_ROUNDS);

  const admin = await prisma.user.upsert({
    where: { email: adminEmail },
    update: {},
    create: {
      name: 'Admin',
      email: adminEmail,
      passwordHash: adminHash,
      role: Role.ADMIN,
      isActive: true,
    },
  });
  console.log('Admin created:', admin.email);

  // 2. Customer
  const customerHash = await bcrypt.hash('Test@1234!', BCRYPT_ROUNDS);
  const customer = await prisma.user.upsert({
    where: { email: 'customer@test.com' },
    update: {},
    create: {
      name: 'Priya Shrestha',
      email: 'customer@test.com',
      passwordHash: customerHash,
      role: Role.CUSTOMER,
      isActive: true,
    },
  });
  console.log('Customer created:', customer.email);

  // 3. Vendor 1 (APPROVED) - Green Bites Cafe
  const vendorHash = await bcrypt.hash('Test@1234!', BCRYPT_ROUNDS);
  const vendorUser1 = await prisma.user.upsert({
    where: { email: 'vendor@test.com' },
    update: {},
    create: {
      name: 'Green Bites Owner',
      email: 'vendor@test.com',
      passwordHash: vendorHash,
      role: Role.VENDOR,
      isActive: true,
    },
  });

  let vendor1 = await prisma.vendor.findUnique({ where: { userId: vendorUser1.id } });
  if (!vendor1) {
    vendor1 = await prisma.vendor.create({
      data: {
        userId: vendorUser1.id,
        businessName: 'Green Bites Cafe',
        businessType: 'Cafe',
        address: 'Thamel, Kathmandu',
        lat: 27.7152,
        lng: 85.3123,
        status: VendorStatus.APPROVED,
      },
    });
  }
  console.log('Vendor 1 created:', vendor1.businessName);

  // 4. Vendor 2 (PENDING) - Annapurna Bakery
  const vendor2Hash = await bcrypt.hash('Test@1234!', BCRYPT_ROUNDS);
  const vendorUser2 = await prisma.user.upsert({
    where: { email: 'vendor2@test.com' },
    update: {},
    create: {
      name: 'Annapurna Bakery Owner',
      email: 'vendor2@test.com',
      passwordHash: vendor2Hash,
      role: Role.VENDOR,
      isActive: true,
    },
  });

  let vendor2 = await prisma.vendor.findUnique({ where: { userId: vendorUser2.id } });
  if (!vendor2) {
    vendor2 = await prisma.vendor.create({
      data: {
        userId: vendorUser2.id,
        businessName: 'Annapurna Bakery',
        businessType: 'Bakery',
        address: 'Patan, Lalitpur',
        lat: 27.6772,
        lng: 85.3163,
        status: VendorStatus.PENDING,
      },
    });
  }
  console.log('Vendor 2 created:', vendor2.businessName);

  // 5. Five listings for Green Bites Cafe
  const now = new Date();
  const pickupStart = new Date(now.getTime() + 60 * 60 * 1000); // now + 1 hour
  const pickupEnd = new Date(now.getTime() + 6 * 60 * 60 * 1000); // now + 6 hours

  const listingsData = [
    {
      name: 'Momo Box (15 pcs)',
      description: 'Fresh steamed momos with tomato chutney',
      category: ListingCategory.CAFE,
      originalPrice: 25000,
      discountedPrice: 10000,
      quantity: 10,
      availableQty: 10,
    },
    {
      name: 'Samosa Pack (6 pcs)',
      description: 'Crispy vegetable samosas',
      category: ListingCategory.BAKERY,
      originalPrice: 15000,
      discountedPrice: 6000,
      quantity: 8,
      availableQty: 8,
    },
    {
      name: 'Bread Ends Bag',
      description: 'Assorted bread ends and loaves',
      category: ListingCategory.BAKERY,
      originalPrice: 8000,
      discountedPrice: 3000,
      quantity: 15,
      availableQty: 15,
    },
    {
      name: 'Rice Meal Set',
      description: 'Dal bhat with seasonal vegetables',
      category: ListingCategory.RESTAURANT,
      originalPrice: 30000,
      discountedPrice: 12000,
      quantity: 5,
      availableQty: 5,
    },
    {
      name: 'Pastry Mix Box',
      description: 'Assorted pastries and sweets',
      category: ListingCategory.SWEETS,
      originalPrice: 20000,
      discountedPrice: 8000,
      quantity: 12,
      availableQty: 12,
    },
  ];

  for (const listingData of listingsData) {
    const existing = await prisma.listing.findFirst({
      where: { vendorId: vendor1.id, name: listingData.name },
    });
    if (!existing) {
      await prisma.listing.create({
        data: {
          ...listingData,
          vendorId: vendor1.id,
          pickupStart,
          pickupEnd,
          isActive: true,
        },
      });
      console.log('Listing created:', listingData.name);
    }
  }

  console.log('Seeding complete!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
