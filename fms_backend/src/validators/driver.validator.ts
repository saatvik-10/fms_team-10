import { z } from 'zod';

const expiryDateSchema = z
  .string()
  .trim()
  .refine((value) => {
    const isoDatePattern = /^\d{4}-\d{2}-\d{2}$/;
    const ddMmYyyyPattern = /^\d{2}-\d{2}-\d{4}$/;

    if (!isoDatePattern.test(value) && !ddMmYyyyPattern.test(value)) {
      return false;
    }

    const normalized = ddMmYyyyPattern.test(value)
      ? `${value.slice(6, 10)}-${value.slice(3, 5)}-${value.slice(0, 2)}`
      : value;

    const parsed = new Date(`${normalized}T00:00:00.000Z`);
    return !Number.isNaN(parsed.getTime());
  }, 'Expiry date must be a valid date in YYYY-MM-DD or DD-MM-YYYY format');

export const createDriverSchema = z.object({
  fullName: z.string().trim().min(1, 'Full name is required'),
  email: z.string().trim().email('A valid email is required'),
  phone: z.string().trim().min(10, 'Phone number is required'),
  address: z.string().trim().min(1, 'Address is required').optional(),
  licenseNumber: z.string().trim().min(1, 'License number is required'),
  expiryDate: expiryDateSchema,
  classes: z
    .array(z.string().trim().min(1, 'Class cannot be empty'))
    .min(1, 'At least one class is required')
    .refine(
      (items) => new Set(items).size === items.length,
      'Classes must not contain duplicates',
    ),
});

export type CreateDriverInput = z.infer<typeof createDriverSchema>;

export const updateVehicleDistanceSchema = z.object({
  vehicleId: z.string().trim().min(1, 'Vehicle id is required'),
  increment: z
    .number()
    .int('Increment must be an integer')
    .positive('Increment must be greater than 0'),
});

export type UpdateVehicleDistanceInput = z.infer<
  typeof updateVehicleDistanceSchema
>;
