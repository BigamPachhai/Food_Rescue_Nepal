-- CreateTable
CREATE TABLE "vendor_favorites" (
    "userId" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "vendor_favorites_pkey" PRIMARY KEY ("userId","vendorId")
);

-- AddForeignKey
ALTER TABLE "vendor_favorites" ADD CONSTRAINT "vendor_favorites_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vendor_favorites" ADD CONSTRAINT "vendor_favorites_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;
