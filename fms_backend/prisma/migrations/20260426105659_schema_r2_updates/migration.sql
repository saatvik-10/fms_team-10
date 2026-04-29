/*
  Warnings:

  - You are about to drop the column `dlBackImageKey` on the `Driver` table. All the data in the column will be lost.
  - You are about to drop the column `dlFrontImageKey` on the `Driver` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Driver" DROP COLUMN "dlBackImageKey",
DROP COLUMN "dlFrontImageKey";
