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
  licenseNumber: z
    .string()
    .trim()
    .min(1, 'License number is required')
    .max(15, 'License number is required'),
  expiryDate: expiryDateSchema,
  licenseFrontImage: z
    .string()
    .trim()
    .min(1, 'Front license image is required'),
  licenseBackImage: z
    .string()
    .trim()
    .min(1, 'Back license image is required'),
  classes: z
    .array(z.string().trim().min(1, 'Class cannot be empty'))
    .min(1, 'At least one class is required')
    .refine(
      (items) => new Set(items).size === items.length,
      'Classes must not contain duplicates',
    ),
});

export type CreateDriverInput = z.infer<typeof createDriverSchema>;

export const updateDriverSchema = z
  .object({
    fullName: z.string().trim().min(1, 'Full name is required').optional(),
    email: z.string().trim().email('A valid email is required').optional(),
    phone: z.string().trim().min(10, 'Phone number is required').optional(),
    licenseNumber: z
      .string()
      .trim()
      .min(1, 'License number is required')
      .max(15, 'License number is required')
      .optional(),
    expiryDate: expiryDateSchema.optional(),
    classes: z
      .array(z.string().trim().min(1, 'Class cannot be empty'))
      .min(1, 'At least one class is required')
      .refine(
        (items) => new Set(items).size === items.length,
        'Classes must not contain duplicates',
      )
      .optional(),
  })
  .refine(
    (data) => Object.values(data).some((value) => value !== undefined),
    'At least one field is required',
  );

export type UpdateDriverInput = z.infer<typeof updateDriverSchema>;

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
