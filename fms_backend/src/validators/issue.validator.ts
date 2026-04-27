import { z } from 'zod';

export const createIssueReportSchema = z.object({
  tripId: z.string().trim().min(1).optional(),
  transcript: z.string().trim().min(1, 'Issue transcript is required').max(5000),
  incidentLocation: z
    .string()
    .trim()
    .min(1, 'Incident location is required')
    .max(500),
  vehicleUnit: z.string().trim().min(1, 'Vehicle unit is required').max(100),
  images: z.array(z.string().trim().min(1)).max(6).optional().default([]),
});

export const getIssueReportsQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(50).optional(),
});

export type CreateIssueReportInput = z.infer<typeof createIssueReportSchema>;
