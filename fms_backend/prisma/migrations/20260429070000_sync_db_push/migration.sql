-- CreateEnum
CREATE TYPE "WorkOrderStatus" AS ENUM ('PROGRESS', 'COMPLETED');

-- AlterEnum
ALTER TYPE "TripStatus" ADD VALUE 'SCHEDULED';

-- AlterEnum
ALTER TYPE "VehicleStatus" ADD VALUE 'SCHEDULED';

-- AlterTable
ALTER TABLE "WorkOrder" ADD COLUMN "tripId" TEXT;

-- AlterTable
ALTER TABLE "Trips" ADD COLUMN "status" TEXT NOT NULL DEFAULT 'PENDING';

-- DropIndex
DROP INDEX IF EXISTS "WorkOrder_vehicleId_idx";
