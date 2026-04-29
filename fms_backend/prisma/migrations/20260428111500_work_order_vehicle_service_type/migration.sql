-- AlterTable
ALTER TABLE "WorkOrder" ADD COLUMN "serviceType" TEXT;
ALTER TABLE "WorkOrder" ADD COLUMN "vehicleId" TEXT;

-- CreateIndex
CREATE INDEX "WorkOrder_vehicleId_idx" ON "WorkOrder"("vehicleId");

-- AddForeignKey
ALTER TABLE "WorkOrder" ADD CONSTRAINT "WorkOrder_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "vehicles"("id") ON DELETE SET NULL ON UPDATE CASCADE;
