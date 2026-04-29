/*
  Warnings:

  - You are about to drop the column `newOdometerReading` on the `Vehicle` table. All the data in the column will be lost.
  - You are about to drop the column `odometerReading` on the `Vehicle` table. All the data in the column will be lost.
  - Added the required column `totalDistance` to the `Vehicle` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Vehicle" DROP COLUMN "newOdometerReading",
DROP COLUMN "odometerReading",
ADD COLUMN     "totalDistance" INTEGER NOT NULL;
