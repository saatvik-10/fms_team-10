import { z } from 'zod';

export const loginSchema = z.object({
  email: z.string().email("Email is required"),
  password: z.string().min(8),
});

export const managerLoginSchema = z.object({
  username: z.string().min(1, 'Username is required'),
  password: z.string().min(1, 'Password is required'),
});

export type LoginInput = z.infer<typeof loginSchema>;
export type ManagerLoginInput = z.infer<typeof managerLoginSchema>;
