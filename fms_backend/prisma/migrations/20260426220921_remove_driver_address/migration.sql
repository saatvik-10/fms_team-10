/*
  Warnings:

  - You are about to drop the column `address` on the `Driver` table. All the data in the column will be lost.
  - Made the column `phone` on table `Driver` required. This step will fail if there are existing NULL values in that column.
  - Made the column `email` on table `Driver` required. This step will fail if there are existing NULL values in that column.
  - Made the column `licenceNumber` on table `Driver` required. This step will fail if there are existing NULL values in that column.
  - Made the column `expiryDate` on table `Driver` required. This step will fail if there are existing NULL values in that column.
  - Made the column `phone` on table `Maintenance` required. This step will fail if there are existing NULL values in that column.
  - Made the column `email` on table `Maintenance` required. This step will fail if there are existing NULL values in that column.

*/
-- AlterTable
ALTER TABLE "Driver" DROP COLUMN "address",
ALTER COLUMN "phone" SET NOT NULL,
ALTER COLUMN "email" SET NOT NULL,
ALTER COLUMN "licenceNumber" SET NOT NULL,
ALTER COLUMN "expiryDate" SET NOT NULL;

-- AlterTable
ALTER TABLE "Maintenance" ALTER COLUMN "phone" SET NOT NULL,
ALTER COLUMN "email" SET NOT NULL;
