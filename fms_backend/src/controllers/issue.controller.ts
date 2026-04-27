import type { Context } from 'hono';
import { prisma } from '../../prisma';
import { createIssueReportSchema, getIssueReportsQuerySchema } from '../validators/issue.validator';
import { decodeBase64Image, deleteUploadedKeys, getImageMeta } from '../lib/utils';
import { R2Service } from '../services/r2.service';
import { nanoid } from 'nanoid';

const r2Service = new R2Service();

async function getSignedImageUrls(imageKeys: string[]) {
  if (!imageKeys.length) {
    return [] as string[];
  }

  const signed = await Promise.allSettled(
    imageKeys.map((key) => r2Service.getSignedDownloadUrl(key)),
  );

  return signed
    .map((item) => (item.status === 'fulfilled' ? item.value : null))
    .filter((item): item is string => Boolean(item));
}

export class IssueController {
  async createIssueReport(c: Context) {
    const body = await c.req.json();
    const result = createIssueReportSchema.safeParse(body);

    if (!result.success) {
      return c.json(
        { err: 'Invalid input', details: result.error.flatten() },
        400,
      );
    }

    const userId = c.get('userId') as string;
    const { tripId, transcript, incidentLocation, vehicleUnit, images } = result.data;
    let resolvedTripId: string | null = null;

    if (tripId) {
      const driver = await prisma.driver.findUnique({
        where: { userId },
        select: { id: true },
      });

      if (!driver) {
        return c.json({ err: 'Driver profile not found' }, 404);
      }

      const trip = await prisma.trips.findFirst({
        where: {
          id: tripId,
          driver: driver.id,
        },
        select: { id: true },
      });

      if (trip) {
        resolvedTripId = trip.id;
      }
    }

    const uploadedKeys: string[] = [];

    try {
      for (let index = 0; index < images.length; index += 1) {
        const image = images[index]!;
        const { contentType, extension } = getImageMeta(image);

        const uploaded = await r2Service.uploadByScope({
          scope: {
            role: 'driver',
            userId,
          },
          fileName: `issue_${Date.now()}_${index + 1}_${nanoid(4)}.${extension}`,
          body: decodeBase64Image(image),
          contentType,
        });

        uploadedKeys.push(uploaded.key);
      }

      const issue = await prisma.issueReport.create({
        data: {
          driverUserId: userId,
          tripId: resolvedTripId,
          transcript,
          incidentLocation,
          vehicleUnit,
          imageKeys: uploadedKeys,
        },
      });

      const imageUrls = await getSignedImageUrls(issue.imageKeys);

      return c.json(
        {
          message: 'Issue report submitted successfully',
          issue: {
            ...issue,
            imageUrls,
          },
        },
        201,
      );
    } catch (error) {
      await deleteUploadedKeys(uploadedKeys);
      throw error;
    }
  }

  async getIssueReports(c: Context) {
    const queryResult = getIssueReportsQuerySchema.safeParse({
      limit: c.req.query('limit'),
    });

    if (!queryResult.success) {
      return c.json(
        { err: 'Invalid query params', details: queryResult.error.flatten() },
        400,
      );
    }

    const userId = c.get('userId') as string;
    const limit = queryResult.data.limit ?? 20;

    const reports = await prisma.issueReport.findMany({
      where: { driverUserId: userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });

    const hydrated = await Promise.all(
      reports.map(async (report) => ({
        ...report,
        imageUrls: await getSignedImageUrls(report.imageKeys),
      })),
    );

    return c.json({ issues: hydrated });
  }

  async getIssueReportById(c: Context) {
    const userId = c.get('userId') as string;
    const issueId = c.req.param('issueId');

    const issue = await prisma.issueReport.findFirst({
      where: {
        id: issueId,
        driverUserId: userId,
      },
    });

    if (!issue) {
      return c.json({ err: 'Issue report not found' }, 404);
    }

    const imageUrls = await getSignedImageUrls(issue.imageKeys);

    return c.json({
      issue: {
        ...issue,
        imageUrls,
      },
    });
  }
}
