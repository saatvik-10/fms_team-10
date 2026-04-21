import { z } from 'zod';

export const superAdminLoginSchema = z.object({
  email: z.string().email("Username is required"),
  password: z.string().min(8),
});

export const loginSchema = z.object({
  username: z.string().min(1, 'Username is required'),
  password: z.string().min(1, 'Password is required'),
});

export type LoginInput = z.infer<typeof superAdminLoginSchema>;
export type ManagerLoginInput = z.infer<typeof loginSchema>;
