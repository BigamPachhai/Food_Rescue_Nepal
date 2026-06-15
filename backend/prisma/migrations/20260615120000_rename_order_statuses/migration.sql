-- Drop default before altering type
ALTER TABLE "orders" ALTER COLUMN "status" DROP DEFAULT;

-- Rename existing enum to backup
ALTER TYPE "OrderStatus" RENAME TO "OrderStatus_old";

-- Create new clean enum with correct status names
CREATE TYPE "OrderStatus" AS ENUM ('PENDING', 'ACCEPTED', 'READY', 'COMPLETED', 'CANCELLED', 'REJECTED', 'EXPIRED');

-- Migrate column with data transformation
ALTER TABLE "orders"
  ALTER COLUMN "status" TYPE "OrderStatus"
  USING CASE "status"::text
    WHEN 'CONFIRMED' THEN 'ACCEPTED'
    WHEN 'PICKED_UP' THEN 'COMPLETED'
    WHEN 'NO_SHOW'   THEN 'EXPIRED'
    ELSE "status"::text
  END::"OrderStatus";

-- Restore default value with new type
ALTER TABLE "orders" ALTER COLUMN "status" SET DEFAULT 'PENDING'::"OrderStatus";

-- Drop old enum
DROP TYPE "OrderStatus_old";
