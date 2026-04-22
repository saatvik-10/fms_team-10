import { z } from 'zod';

export const createMaintenanceSchema = z.object({
  name: z.string().trim().min(1, 'Name is required'),
  dob: z
    .string()
    .trim()
    .refine((value) => !Number.isNaN(Date.parse(value)), 'DOB must be a valid date'),
  email: z.string().trim().email('A valid email is required'),
  phone: z.string().trim().min(10, 'Phone number is required'),
});

export type CreateMaintenanceInput = z.infer<typeof createMaintenanceSchema>;
