-- AlterTable
DO $$
BEGIN
	IF EXISTS (
		SELECT 1
		FROM information_schema.tables
		WHERE table_schema = 'public'
		  AND table_name = 'issue_reports'
	) THEN
		ALTER TABLE "issue_reports" ALTER COLUMN "imageKeys" DROP DEFAULT;
	END IF;
END $$;
