import { z } from 'zod';

const dobSchema = z
  .string()
  .trim()
  .refine((value) => !Number.isNaN(Date.parse(value)), 'DOB must be a valid date');

const dateSchema = z
  .string()
  .trim()
  .refine((value) => !Number.isNaN(Date.parse(value)), 'Date must be a valid date');

const prioritySchema = z.enum(['LOW', 'MEDIUM', 'HIGH']);

export const createMaintenanceSchema = z.object({
  name: z.string().trim().min(1, 'Name is required'),
  dob: dobSchema,
  email: z.string().trim().email('A valid email is required'),
  phone: z.string().trim().min(10, 'Phone number is required'),
});

export type CreateMaintenanceInput = z.infer<typeof createMaintenanceSchema>;

export const updateMaintenanceSchema = z
  .object({
    name: z.string().trim().min(1, 'Name is required').optional(),
    email: z.string().trim().email('A valid email is required').optional(),
    phone: z.string().trim().min(10, 'Phone number is required').optional(),
    dob: dobSchema.optional(),
  })
  .refine(
    (data) => Object.values(data).some((value) => value !== undefined),
    'At least one field is required',
  );

export type UpdateMaintenanceInput = z.infer<typeof updateMaintenanceSchema>;

export const createWorkOrderSchema = z.object({
  vehicleId: z.string().trim().min(1, 'Vehicle is required'),
  title: z.string().trim().min(1, 'Title is required'),
  serviceType: z.string().trim().min(1, 'Service type is required').optional(),
  priority: prioritySchema,
  date: dateSchema,
  taskDetails: z.string().trim().min(1, 'Task details are required'),
  mediaImages: z.array(z.string().trim().min(1)).optional().default([]),
});

export type CreateWorkOrderInput = z.infer<typeof createWorkOrderSchema>;
