import { z } from 'zod';

export const createVehicleSchema = z.object({
  ownerName: z.string().min(2, 'Name must be a bit long'),
  vehicleModel: z.string().min(3, 'Vehicle model is required'),
  registrationNum: z.string().min(10).max(10),
  chassisNum: z.string().min(5, 'Chassis number is required'),
  odometerReading: z.string(),
});

export type CreateVehicleType = z.infer<typeof createVehicleSchema>;
