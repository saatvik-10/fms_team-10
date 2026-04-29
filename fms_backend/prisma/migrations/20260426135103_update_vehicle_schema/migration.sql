/*
  Warnings:

  - You are about to drop the `Vehicle` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `VehicleInfo` table. If the table is not empty, all the data it contains will be lost.

*/
-- CreateEnum
CREATE TYPE "VehicleStatus" AS ENUM ('AVAILABLE', 'IN_TRANSIT', 'MAINTENANCE', 'OUT_OF_SERVICE');

-- CreateEnum
CREATE TYPE "TripStatus" AS ENUM ('PENDING', 'IN_TRANSIT', 'COMPLETED', 'CANCELLED');

-- DropForeignKey
ALTER TABLE "Vehicle" DROP CONSTRAINT "Vehicle_createdById_fkey";

-- DropForeignKey
ALTER TABLE "VehicleInfo" DROP CONSTRAINT "VehicleInfo_vehicleId_fkey";

-- DropTable
DROP TABLE "Vehicle";

-- DropTable
DROP TABLE "VehicleInfo";

-- CreateTable
CREATE TABLE "vehicles" (
    "id" TEXT NOT NULL,
    "make" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "status" "VehicleStatus" NOT NULL DEFAULT 'AVAILABLE',
    "imageName" TEXT,
    "year" TEXT,
    "color" TEXT,
    "operationalStatus" TEXT DEFAULT 'OPERATIONAL',
    "assessmentReason" TEXT,
    "chassis_num" TEXT NOT NULL,
    "registration_num" TEXT NOT NULL,
    "rcImageUrl" TEXT,
    "vehicleImageUrl" TEXT,
    "assignedDriverId" TEXT,
    "createdById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "vehicles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vehicle_trips" (
    "id" TEXT NOT NULL,
    "vehicleId" TEXT NOT NULL,
    "origin" TEXT NOT NULL,
    "destination" TEXT NOT NULL,
    "progress" DOUBLE PRECISION NOT NULL,
    "eta" TEXT,
    "date" TEXT,
    "distance" TEXT,
    "duration" TEXT,
    "costEstimate" TEXT,
    "startTime" TIMESTAMP(3),
    "status" "TripStatus" NOT NULL DEFAULT 'PENDING',
    "productType" TEXT,
    "loadAmount" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "vehicle_trips_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vehicle_maintenance" (
    "id" TEXT NOT NULL,
    "vehicleId" TEXT NOT NULL,
    "nextService" TEXT,
    "inspectionStatus" TEXT,
    "alerts" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "vehicle_maintenance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trip_history" (
    "id" TEXT NOT NULL,
    "vehicleId" TEXT NOT NULL,
    "vehicleID" TEXT NOT NULL,
    "origin" TEXT NOT NULL,
    "destination" TEXT NOT NULL,
    "progress" DOUBLE PRECISION NOT NULL,
    "eta" TEXT,
    "date" TEXT,
    "distance" TEXT,
    "duration" TEXT,
    "costEstimate" TEXT,
    "startTime" TIMESTAMP(3),
    "status" "TripStatus" NOT NULL DEFAULT 'PENDING',
    "productType" TEXT,
    "loadAmount" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "trip_history_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "vehicles_chassis_num_key" ON "vehicles"("chassis_num");

-- CreateIndex
CREATE UNIQUE INDEX "vehicles_registration_num_key" ON "vehicles"("registration_num");

-- CreateIndex
CREATE UNIQUE INDEX "vehicles_assignedDriverId_key" ON "vehicles"("assignedDriverId");

-- CreateIndex
CREATE UNIQUE INDEX "vehicle_trips_vehicleId_key" ON "vehicle_trips"("vehicleId");

-- CreateIndex
CREATE UNIQUE INDEX "vehicle_maintenance_vehicleId_key" ON "vehicle_maintenance"("vehicleId");

-- AddForeignKey
ALTER TABLE "vehicles" ADD CONSTRAINT "vehicles_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
