-- AlterTable
ALTER TABLE "vehicles" ADD COLUMN     "newOdometerReading" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "odometerReading" INTEGER NOT NULL DEFAULT 0;
