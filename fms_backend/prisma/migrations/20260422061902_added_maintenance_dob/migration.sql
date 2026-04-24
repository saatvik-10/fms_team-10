/*
  Warnings:

  - You are about to drop the column `age` on the `Maintenance` table. All the data in the column will be lost.
  - Added the required column `dob` to the `Maintenance` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Maintenance" DROP COLUMN "age",
ADD COLUMN     "dob" TIMESTAMP(3) NOT NULL;
