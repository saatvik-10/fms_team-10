-- AlterTable
ALTER TABLE "Trips" DROP COLUMN "driver",
DROP COLUMN "vehicle",
ADD COLUMN     "driverId" TEXT,
ADD COLUMN     "vehicleId" TEXT;

-- AddForeignKey
ALTER TABLE "Trips" ADD CONSTRAINT "Trips_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "vehicles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Trips" ADD CONSTRAINT "Trips_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "Driver"("id") ON DELETE SET NULL ON UPDATE CASCADE;
