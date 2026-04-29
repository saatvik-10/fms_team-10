-- DropIndex
DROP INDEX IF EXISTS "WorkOrder_vehicleId_idx";

-- AlterTable
ALTER TABLE "WorkOrder" ADD COLUMN     "status" TEXT NOT NULL DEFAULT 'PROGRESS',
ADD COLUMN     "totalCost" DOUBLE PRECISION NOT NULL DEFAULT 0,
ADD COLUMN     "vehicleNum" TEXT NOT NULL DEFAULT 'UNKNOWN';

-- AlterTable
ALTER TABLE "vehicles" ADD COLUMN     "capacityUnit" TEXT NOT NULL DEFAULT 'KG',
ADD COLUMN     "maxLoadCapacity" DOUBLE PRECISION NOT NULL DEFAULT 0,
ADD COLUMN     "totalMaintenanceCost" DOUBLE PRECISION NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE "inspections" (
    "id" TEXT NOT NULL,
    "workOrderId" TEXT,
    "title" TEXT NOT NULL,
    "vehicleId" TEXT NOT NULL,
    "unitName" TEXT NOT NULL,
    "unitVIN" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL,
    "type" TEXT NOT NULL,
    "vehicleType" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'Pending',
    "priority" TEXT NOT NULL DEFAULT 'Medium',
    "items" JSONB NOT NULL,
    "consumedParts" JSONB,
    "notes" TEXT,
    "taskDetails" TEXT,
    "maintenanceStaffId" TEXT NOT NULL,
    "isEmergency" BOOLEAN NOT NULL DEFAULT false,
    "odometer" TEXT NOT NULL,
    "fuelLevel" TEXT NOT NULL,
    "imageUrls" TEXT[],
    "reportUrl" TEXT,
    "maintenanceId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "inspections_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "inspections_workOrderId_key" ON "inspections"("workOrderId");

-- AddForeignKey
ALTER TABLE "inspections" ADD CONSTRAINT "inspections_workOrderId_fkey" FOREIGN KEY ("workOrderId") REFERENCES "WorkOrder"("id") ON DELETE SET NULL ON UPDATE CASCADE;
