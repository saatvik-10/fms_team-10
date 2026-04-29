import type { Context } from 'hono';
import { prisma } from '../../prisma';
import { createTripSchema } from '../validators/trip.validator';
import {
  TripStatus,
  VehicleStatus,
  WorkOrderStatus,
  Priority,
} from '../../generated/prisma';

export class Trip {
  async createTrip(c: Context) {
    const body = await c.req.json();
    const result = createTripSchema.safeParse(body);
    const userId = c.get('userId') as string;

    if (!result.success) {
      return c.json(
        { err: 'Invalid input', details: result.error.flatten() },
        400,
      );
    }

    const data = result.data;
    const [vehicle, driver, maintenanceStaff] = await Promise.all([
      prisma.vehicle.findFirst({
        where: {
          createdById: userId,
          OR: [{ id: data.vehicle }, { registrationNumber: data.vehicle }],
        },
        select: { id: true, registrationNumber: true, model: true },
      }),
      prisma.driver.findFirst({
        where: {
          OR: [{ id: data.driver }, { user: { username: data.driver } }],
        },
        select: { id: true },
      }),
      prisma.maintenance.findFirst({
        where: {
          user: {
            createdById: userId,
          },
        },
        select: { id: true },
      }),
    ]);

    if (!vehicle) {
      return c.json({ err: 'Vehicle not found' }, 404);
    }

    if (!driver) {
      return c.json({ err: 'Driver not found' }, 404);
    }

    const trip = await prisma.$transaction(async (tx) => {
      const newTrip = await tx.trips.create({
        data: {
          sourceLocation: data.sourceLocation,
          destinationLocation: data.destinationLocation,
          productType: data.productType,
          unit: data.unit,
          amount: data.amount,
          vehicleId: vehicle.id,
          driverId: driver.id,
          departureTime: data.departureTime,
          createdById: userId,
          status: TripStatus.SCHEDULED,
        },
      });

      await tx.vehicle.updateMany({
        where: {
          assignedDriverId: driver.id,
          id: { not: vehicle.id },
        },
        data: { assignedDriverId: null },
      });

      await tx.vehicle.update({
        where: { id: vehicle.id },
        data: {
          status: VehicleStatus.MAINTENANCE,
          assignedDriverId: driver.id,
        },
      });

      if (maintenanceStaff) {
        await tx.workOrder.create({
          data: {
            vehicleId: vehicle.id,
            vehicleName: vehicle.model,
            vehicleNum: vehicle.registrationNumber,
            title: `Pre-trip Inspection - ${vehicle.registrationNumber}`,
            serviceType: 'Pre-trip Inspection',
            priority: Priority.HIGH,
            date: new Date(),
            taskDetails: `Standard pre-trip inspection for trip from ${data.sourceLocation} to ${data.destinationLocation}`,
            maintenanceId: maintenanceStaff.id,
            status: WorkOrderStatus.PROGRESS,
            tripId: newTrip.id,
          },
        });
      }

      await tx.vehicleTrip.upsert({
        where: { vehicleId: vehicle.id },
        update: {
          origin: data.sourceLocation,
          destination: data.destinationLocation,
          progress: 0.0,
          eta: null,
          date: data.departureTime,
          distance: data.distance ?? null,
          duration: null,
          costEstimate: null,
          startTime: new Date(),
          status: TripStatus.SCHEDULED,
          productType: data.productType,
          loadAmount: `${data.amount} ${data.unit}`,
        },
        create: {
          vehicleId: vehicle.id,
          origin: data.sourceLocation,
          destination: data.destinationLocation,
          progress: 0.0,
          eta: null,
          date: data.departureTime,
          distance: data.distance ?? null,
          duration: null,
          costEstimate: null,
          startTime: new Date(),
          status: TripStatus.SCHEDULED,
          productType: data.productType,
          loadAmount: `${data.amount} ${data.unit}`,
        },
      });

      await tx.driver.update({
        where: { id: driver.id },
        data: { status: 'ON_TRIP' },
      });

      return newTrip;
    });

    return c.json({ message: 'Trip created successfully', trip }, 201);
  }

  async getTrip(c: Context) {
    const tripId = c.req.query('id');
    const userId = c.get('userId') as string;
    const role = c.get('role') as string;

    if (!tripId) {
      return c.json({ err: 'Trip id is required as query param: ?id=' }, 400);
    }

    let trip = null;

    if (role === 'MANAGER') {
      trip = await prisma.trips.findFirst({
        where: {
          id: tripId,
          createdById: userId,
        },
        include: {
          vehicle: true,
          driver: true,
        },
      });
    } else if (role === 'DRIVER') {
      const driver = await prisma.driver.findUnique({
        where: { userId },
        select: { id: true },
      });

      if (!driver) {
        return c.json({ err: 'Driver profile not found' }, 404);
      }

      trip = await prisma.trips.findFirst({
        where: {
          id: tripId,
          driverId: driver.id,
        },
        include: {
          vehicle: true,
          driver: true,
        },
      });
    }

    if (!trip) {
      return c.json({ err: 'Trip not found' }, 404);
    }

    return c.json({ trip });
  }

  async getTrips(c: Context) {
    const userId = c.get('userId') as string;
    const trips = await prisma.trips.findMany({
      where: {
        createdById: userId,
      },
      orderBy: {
        createdAt: 'desc',
      },
      include: {
        vehicle: {
          select: {
            id: true,
            registrationNumber: true,
            model: true,
            status: true,
          },
        },
        driver: {
          select: {
            id: true,
            name: true,
            phone: true,
            status: true,
          },
        },
      },
    });

    return c.json({ trips });
  }

  async getDriverTrips(c: Context) {
    const userId = c.get('userId') as string;
    const driver = await prisma.driver.findUnique({
      where: { userId },
      select: { id: true },
    });

    if (!driver) {
      return c.json({ trips: [] });
    }

    const trips = await prisma.trips.findMany({
      where: {
        driverId: driver.id,
      },
      orderBy: {
        createdAt: 'desc',
      },
      include: {
        vehicle: {
          select: {
            id: true,
            registrationNumber: true,
          },
        },
        driver: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    const vehicleIds = Array.from(
      new Set(trips.map((trip) => trip.vehicleId!).filter(Boolean)),
    );

    const vehicleTrips = await prisma.vehicleTrip.findMany({
      where: { vehicleId: { in: vehicleIds } },
      select: {
        vehicleId: true,
        status: true,
        loadAmount: true,
        date: true,
        distance: true,
      },
    });

    const tripByVehicleId = new Map(
      vehicleTrips.map((vt) => [vt.vehicleId, vt]),
    );

    const enrichedTrips = trips.map((trip) => {
      const vehicleTrip = tripByVehicleId.get(trip.vehicleId!);

      return {
        ...trip,
        vehicleRegistrationNumber: trip.vehicle?.registrationNumber ?? null,
        status: vehicleTrip?.status ?? trip.status ?? 'PENDING',
        loadAmount: vehicleTrip?.loadAmount ?? null,
        tripDate: vehicleTrip?.date ?? trip.departureTime,
        tripDistance: vehicleTrip?.distance ?? null,
        distanceKm: vehicleTrip?.distance ?? null,
      };
    });

    return c.json({ trips: enrichedTrips });
  }

  async deleteTrip(c: Context) {
    const tripId = c.req.param('id');
    const userId = c.get('userId') as string;

    if (!tripId) {
      return c.json({ err: 'Trip id is required' }, 400);
    }

    const trip = await prisma.trips.findFirst({
      where: {
        id: tripId,
        createdById: userId,
      },
      select: { id: true, vehicleId: true, driverId: true },
    });

    if (!trip) {
      return c.json({ err: 'Trip not found' }, 404);
    }

    await prisma.$transaction(async (tx) => {
      await tx.trips.delete({
        where: { id: tripId },
      });

      if (trip.vehicleId) {
        await tx.vehicle.update({
          where: { id: trip.vehicleId },
          data: { status: 'AVAILABLE', assignedDriverId: null },
        });

        await tx.vehicleTrip.deleteMany({
          where: { vehicleId: trip.vehicleId },
        });
      }

      if (trip.driverId) {
        await tx.driver.update({
          where: { id: trip.driverId },
          data: { status: 'ACTIVE' },
        });
      }
    });

    return c.json({ message: 'Trip deleted successfully' }, 200);
  }

  // ─────────────────────────────────────────────────────────────
  // DRIVER ACTIONS: start-trip / complete-trip
  // ─────────────────────────────────────────────────────────────

  /**
   * PATCH /trip/start-trip
   * Called by the driver when they tap "Start Trip".
   *
   * Updates:
   *  • trips.status          → IN_TRANSIT
   *  • vehicles.status       → IN_TRANSIT
   *  • vehicle_trips.status  → IN_TRANSIT
   *  • drivers.status        → ON_TRIP
   */
  async startTrip(c: Context) {
    const userId = c.get('userId') as string;
    const { tripId } = await c.req.json<{ tripId: string }>();

    if (!tripId) {
      return c.json({ err: 'tripId is required' }, 400);
    }

    const driver = await prisma.driver.findUnique({
      where: { userId },
      select: { id: true },
    });

    if (!driver) {
      return c.json({ err: 'Driver profile not found' }, 404);
    }

    const trip = await prisma.trips.findFirst({
      where: { id: tripId, driverId: driver.id },
      select: { id: true, vehicleId: true, status: true, departureTime: true },
    });

    if (!trip) {
      return c.json({ err: 'Trip not found or not assigned to you' }, 404);
    }

    // Check if departure time has been reached
    const departureDate = new Date(trip.departureTime);
    if (departureDate > new Date()) {
      return c.json({ err: 'Trip cannot be started before the scheduled departure time' }, 400);
    }

    if (trip.status === 'IN_TRANSIT') {
      return c.json({ err: 'Trip is already in transit' }, 400);
    }

    if (trip.status === 'COMPLETED') {
      return c.json({ err: 'Trip is already completed' }, 400);
    }

    await prisma.$transaction(async (tx) => {
      // 1. Update trip status
      await tx.trips.update({
        where: { id: trip.id },
        data: { status: 'IN_TRANSIT' },
      });

      // 2. Update vehicle status
      if (trip.vehicleId) {
        await tx.vehicle.update({
          where: { id: trip.vehicleId },
          data: { status: 'IN_TRANSIT' },
        });

        // 3. Update vehicleTrip status
        await tx.vehicleTrip.updateMany({
          where: { vehicleId: trip.vehicleId },
          data: { status: 'IN_TRANSIT', startTime: new Date() },
        });
      }

      // 4. Update driver status
      await tx.driver.update({
        where: { id: driver.id },
        data: { status: 'ON_TRIP' },
      });
    });

    return c.json({ message: 'Trip started successfully' });
  }

  /**
   * PATCH /trip/complete-trip
   * Called by the driver when they tap "End Trip".
   *
   * Updates:
   *  • trips.status          → COMPLETED
   *  • vehicles.status       → AVAILABLE
   *  • vehicle_trips.status  → COMPLETED
   *  • drivers.status        → ACTIVE
   */
  async completeTrip(c: Context) {
    const userId = c.get('userId') as string;
    const { tripId } = await c.req.json<{ tripId: string }>();

    if (!tripId) {
      return c.json({ err: 'tripId is required' }, 400);
    }

    const driver = await prisma.driver.findUnique({
      where: { userId },
      select: { id: true },
    });

    if (!driver) {
      return c.json({ err: 'Driver profile not found' }, 404);
    }

    const trip = await prisma.trips.findFirst({
      where: { id: tripId, driverId: driver.id },
      select: { id: true, vehicleId: true, status: true },
    });

    if (!trip) {
      return c.json({ err: 'Trip not found or not assigned to you' }, 404);
    }

    if (trip.status === 'COMPLETED') {
      return c.json({ err: 'Trip is already completed' }, 400);
    }

    await prisma.$transaction(async (tx) => {
      // 1. Update trip status
      await tx.trips.update({
        where: { id: trip.id },
        data: { status: 'COMPLETED' },
      });

      if (trip.vehicleId) {
        // 2. Update vehicle status
        await tx.vehicle.update({
          where: { id: trip.vehicleId },
          data: { status: 'AVAILABLE' },
        });

        // 3. Update vehicleTrip status
        await tx.vehicleTrip.updateMany({
          where: { vehicleId: trip.vehicleId },
          data: { status: 'COMPLETED' },
        });
      }

      // 4. Update driver status
      await tx.driver.update({
        where: { id: driver.id },
        data: { status: 'ACTIVE' },
      });
    });

    return c.json({ message: 'Trip completed successfully' });
  }
}
