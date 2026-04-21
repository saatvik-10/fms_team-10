import type { Context } from 'hono';
import { prisma } from '../../prisma';
import {
  createVehicleSchema,
  type CreateVehicleType,
} from '../validators/vehicle.validator';

export class Vehicle {
  async createVehicle(c: Context) {
    const body = await c.req.json();
    const data = createVehicleSchema.parse(body) as CreateVehicleType;
    const userId = c.get('userId') as string;

    const vehicle = await prisma.vehicle.create({
      data: {
        ownerName: data.ownerName,
        vehicleModel: data.vehicleModel,
        registrationNum: data.registrationNum,
        chassisNum: data.chassisNum,
        odometerReading: data.odometerReading,
        createdById: userId,
      },
    });

    return c.json({ message: 'Vehicle created successfully', vehicle }, 201);
  }

  async getVehicles(c: Context) {
    const userId = c.get('userId') as string;

    const vehicles = await prisma.vehicle.findMany({
      where: {
        createdById: userId,
      },
    });

    return c.json({
      vehicles,
    });
  }
}
