-- CreateEnum
CREATE TYPE "VehiclesAllowed" AS ENUM ('MCWG', 'LMV', 'MVSD');

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "licenceNumber" TEXT,
ADD COLUMN     "vehiclesAllowed" "VehiclesAllowed";
