/*
  Warnings:

  - You are about to drop the column `newOdometerReading` on the `vehicles` table. All the data in the column will be lost.
  - You are about to drop the column `odometerReading` on the `vehicles` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "vehicles" DROP COLUMN "newOdometerReading",
DROP COLUMN "odometerReading";
