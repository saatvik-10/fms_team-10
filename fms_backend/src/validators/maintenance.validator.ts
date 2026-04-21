import { z } from 'zod';

export const createMaintenanceSchema = z.object({
  name: z.string().trim().min(1, 'Name is required'),
  email: z.string().trim().email('A valid email is required'),
  phone: z.string().trim().min(10, 'Phone number is required'),
  address: z.string().trim().min(1, 'Address is required').optional(),
  certification: z.string().trim().min(1, 'Certification is required').optional(),
});

export type CreateMaintenanceInput = z.infer<typeof createMaintenanceSchema>;
