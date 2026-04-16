import { z } from 'zod';

export const createManagerSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  phone: z.string().min(10, 'Phone Number is required'),
  address: z.string().min(1, 'Address is required'),
  email: z.string().email('Email is required'),
});

export type CreateManagerInput = z.infer<typeof createManagerSchema>;
