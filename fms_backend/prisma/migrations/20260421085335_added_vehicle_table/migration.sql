-- CreateTable
CREATE TABLE "Vehicle" (
    "id" TEXT NOT NULL,
    "ownerName" TEXT NOT NULL,
    "vehicleModel" TEXT NOT NULL,
    "registrationNum" TEXT NOT NULL,
    "chassisNum" TEXT NOT NULL,
    "odometerReading" TEXT NOT NULL,
    "createdById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Vehicle_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Vehicle_registrationNum_key" ON "Vehicle"("registrationNum");

-- CreateIndex
CREATE UNIQUE INDEX "Vehicle_chassisNum_key" ON "Vehicle"("chassisNum");

-- AddForeignKey
ALTER TABLE "Vehicle" ADD CONSTRAINT "Vehicle_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
