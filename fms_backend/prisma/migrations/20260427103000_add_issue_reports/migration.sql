-- CreateEnum
CREATE TYPE "IssueReportStatus" AS ENUM ('OPEN', 'RESOLVED');

-- CreateTable
CREATE TABLE "issue_reports" (
    "id" TEXT NOT NULL,
    "driverUserId" TEXT NOT NULL,
    "tripId" TEXT,
    "transcript" TEXT NOT NULL,
    "incidentLocation" TEXT NOT NULL,
    "vehicleUnit" TEXT NOT NULL,
    "imageKeys" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "status" "IssueReportStatus" NOT NULL DEFAULT 'OPEN',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "issue_reports_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "issue_reports_driverUserId_idx" ON "issue_reports"("driverUserId");

-- AddForeignKey
ALTER TABLE "issue_reports" ADD CONSTRAINT "issue_reports_driverUserId_fkey" FOREIGN KEY ("driverUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
