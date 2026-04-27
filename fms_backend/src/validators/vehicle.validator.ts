import { z } from 'zod';

const vehicleStatusEnum = z.enum(['AVAILABLE', 'IN_TRANSIT', 'MAINTENANCE']);
const tripStatusEnum = z.enum(['PENDING', 'IN_TRANSIT', 'COMPLETED', 'CANCELLED']);

export const createVehicleSchema = z.object({
  make: z.string().min(1, 'Make is required'),
  model: z.string().min(1, 'Model is required'),
  type: z.string().min(1, 'Type is required'),
  status: vehicleStatusEnum.optional(),
  imageName: z.string().optional(),
  year: z.string().optional(),
  color: z.string().optional(),
  operationalStatus: z.string().optional(),
  assessmentReason: z.string().optional(),
  chassisNumber: z.string().min(1, 'Chassis number is required'),
  registrationNumber: z.string().min(1, 'Registration number is required'),
  rcDocumentImage: z.string().trim().min(1, 'RC document image is required').optional(),
  vehicleImage: z.string().trim().min(1, 'Vehicle image is required').optional(),
});

export type CreateVehicleType = z.infer<typeof createVehicleSchema>;

export const updateVehicleSchema = z
  .object({
    make: z.string().min(1).optional(),
    model: z.string().min(1).optional(),
    type: z.string().min(1).optional(),
    status: vehicleStatusEnum.optional(),
    imageName: z.string().optional(),
    year: z.string().optional(),
    color: z.string().optional(),
    operationalStatus: z.string().optional(),
    assessmentReason: z.string().optional(),
    chassisNumber: z.string().min(1).optional(),
    registrationNumber: z.string().min(1).optional(),
    rcDocumentImage: z.string().trim().min(1).optional(),
    vehicleImage: z.string().trim().min(1).optional(),
    assignedDriverId: z.string().optional(),
  })
  .refine(
    (data) => Object.values(data).some((value) => value !== undefined),
    'At least one field is required',
  );

export type UpdateVehicleType = z.infer<typeof updateVehicleSchema>;

export const tripHistorySchema = z.object({
  vehicleId: z.string().min(1, 'Vehicle ID is required'),
  vehicleID: z.string().min(1),
  origin: z.string().min(1, 'Origin is required'),
  destination: z.string().min(1, 'Destination is required'),
  progress: z.number().min(0).max(1),
  eta: z.string().optional(),
  date: z.string().optional(),
  distance: z.string().optional(),
  duration: z.string().optional(),
  costEstimate: z.string().optional(),
  startTime: z.string().optional(),
  status: tripStatusEnum.optional(),
  productType: z.string().optional(),
  loadAmount: z.string().optional(),
});

export type TripHistoryType = z.infer<typeof tripHistorySchema>;

export const currentTripSchema = z.object({
  origin: z.string().min(1, 'Origin is required'),
  destination: z.string().min(1, 'Destination is required'),
  progress: z.number().min(0).max(1),
  eta: z.string().optional(),
  date: z.string().optional(),
  distance: z.string().optional(),
  duration: z.string().optional(),
  costEstimate: z.string().optional(),
  startTime: z.string().optional(),
  status: tripStatusEnum.optional(),
  productType: z.string().optional(),
  loadAmount: z.string().optional(),
});

export type CurrentTripType = z.infer<typeof currentTripSchema>;

export const vehicleMaintenanceSchema = z.object({
  nextService: z.string().optional(),
  inspectionStatus: z.string().optional(),
  alerts: z.string().optional(),
});

export type VehicleMaintenanceType = z.infer<typeof vehicleMaintenanceSchema>;