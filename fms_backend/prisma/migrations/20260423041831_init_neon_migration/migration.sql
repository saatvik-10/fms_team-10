/*
  Warnings:

  - Added the required column `status` to the `Driver` table without a default value. This is not possible if the table is not empty.
  - Changed the type of `sourceLocation` on the `Trips` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `destinationLocation` on the `Trips` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- CreateEnum
CREATE TYPE "Status" AS ENUM ('ACTIVE', 'ON_TRIP', 'OFF_DUTY');

-- AlterTable
ALTER TABLE "Driver" ADD COLUMN     "status" "Status" NOT NULL;

-- AlterTable
ALTER TABLE "Trips" DROP COLUMN "sourceLocation",
ADD COLUMN     "sourceLocation" DOUBLE PRECISION NOT NULL,
DROP COLUMN "destinationLocation",
ADD COLUMN     "destinationLocation" DOUBLE PRECISION NOT NULL;
