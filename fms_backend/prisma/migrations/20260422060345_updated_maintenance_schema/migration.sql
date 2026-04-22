/*
  Warnings:

  - You are about to drop the column `address` on the `Maintenance` table. All the data in the column will be lost.
  - You are about to drop the column `certification` on the `Maintenance` table. All the data in the column will be lost.
  - Added the required column `age` to the `Maintenance` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Maintenance" DROP COLUMN "address",
DROP COLUMN "certification",
ADD COLUMN     "age" INTEGER NOT NULL;

-- DropEnum
DROP TYPE "VehiclesAllowed";
