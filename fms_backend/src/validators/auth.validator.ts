import { z } from 'zod';

export const loginSchema = z.object({
  email: z.string().email("Email is required"),
  password: z.string().min(8),
});

export const createManagerSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  phone: z.string().min(10, 'Phone Number is required'),
  address: z.string().min(1, 'Address is required'),
});

export type LoginInput = z.infer<typeof loginSchema>;
export type CreateManagerInput = z.infer<typeof createManagerSchema>;
