/*
  Warnings:

  - You are about to drop the column `address` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `classes` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `expiryDate` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `licenceNumber` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `name` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `phone` on the `User` table. All the data in the column will be lost.

*/
-- DropIndex
DROP INDEX "User_phone_key";

-- AlterTable
ALTER TABLE "User" DROP COLUMN "address",
DROP COLUMN "classes",
DROP COLUMN "expiryDate",
DROP COLUMN "licenceNumber",
DROP COLUMN "name",
DROP COLUMN "phone";

-- CreateTable
CREATE TABLE "Manager" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "phone" TEXT,
    "address" TEXT,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Manager_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Driver" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "phone" TEXT,
    "address" TEXT,
    "email" TEXT,
    "licenceNumber" TEXT,
    "expiryDate" TEXT,
    "classes" TEXT[],
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Driver_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Maintenance" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "phone" TEXT,
    "address" TEXT,
    "email" TEXT,
    "certification" TEXT,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Maintenance_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Manager_phone_key" ON "Manager"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "Manager_userId_key" ON "Manager"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "Driver_phone_key" ON "Driver"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "Driver_email_key" ON "Driver"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Driver_licenceNumber_key" ON "Driver"("licenceNumber");

-- CreateIndex
CREATE UNIQUE INDEX "Driver_userId_key" ON "Driver"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "Maintenance_phone_key" ON "Maintenance"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "Maintenance_email_key" ON "Maintenance"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Maintenance_userId_key" ON "Maintenance"("userId");

-- AddForeignKey
ALTER TABLE "Manager" ADD CONSTRAINT "Manager_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Driver" ADD CONSTRAINT "Driver_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Maintenance" ADD CONSTRAINT "Maintenance_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
