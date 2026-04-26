/*
  Warnings:

  - You are about to drop the column `totalDistance` on the `Vehicle` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Vehicle" DROP COLUMN "totalDistance",
ADD COLUMN     "rcImageUrl" TEXT,
ADD COLUMN     "vehicleImageUrl" TEXT;
