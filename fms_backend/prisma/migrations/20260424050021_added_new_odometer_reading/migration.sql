/*
  Warnings:

  - Added the required column `newOdometerReading` to the `Vehicle` table without a default value. This is not possible if the table is not empty.
  - Changed the type of `odometerReading` on the `Vehicle` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- AlterTable
ALTER TABLE "Vehicle" ADD COLUMN     "newOdometerReading" INTEGER NOT NULL,
DROP COLUMN "odometerReading",
ADD COLUMN     "odometerReading" INTEGER NOT NULL;
