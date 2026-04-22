/*
  Warnings:

  - Added the required column `createdById` to the `Trips` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Trips" ADD COLUMN     "createdById" TEXT NOT NULL;
