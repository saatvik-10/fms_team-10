import { z } from 'zod';

export const createTripSchema = z.object({
	sourceLocation: z.string().trim().min(1, 'Source location is required'),
	destinationLocation: z
		.string()
		.trim()
		.min(1, 'Destination location is required'),
	productType: z.string().trim().min(1, 'Product type is required'),
	unit: z.string().trim().min(1, 'Unit is required'),
	amount: z.number().int().positive('Amount must be greater than 0'),
	vehicle: z.string().trim().min(1, 'Vehicle is required'),
	driver: z.string().trim().min(1, 'Driver is required'),
	departureTime: z
		.string()
		.trim()
		.refine(
			(value) => !Number.isNaN(Date.parse(value)),
			'Departure time must be a valid date/time',
		),
});

export type CreateTripInput = z.infer<typeof createTripSchema>;

