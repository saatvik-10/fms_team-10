import type { Context } from 'hono';
import { prisma } from '../../prisma';
import { createTripSchema } from '../validators/trip.validator';

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
        const [vehicle, driver] = await Promise.all([
            prisma.vehicle.findFirst({
                where: {
                    createdById: userId,
                    OR: [
                        { id: data.vehicle },
                        { registrationNumber: data.vehicle },
                    ],
                },
                select: { id: true },
            }),
            prisma.driver.findFirst({
                where: {
                    OR: [
                        { id: data.driver },
                        { user: { username: data.driver } },
                    ],
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
                    vehicle: vehicle.id,
                    driver: driver.id,
                    departureTime: data.departureTime,
                    createdById: userId,
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
                    status: 'IN_TRANSIT',
                    assignedDriverId: driver.id,
                },
            });

            await tx.vehicleTrip.upsert({
                where: { vehicleId: vehicle.id },
                update: {
                    origin: data.sourceLocation,
                    destination: data.destinationLocation,
                    progress: 0.0,
                    eta: null,
                    date: data.departureTime,
                    distance: null,
                    duration: null,
                    costEstimate: null,
                    startTime: new Date(),
                    status: 'IN_TRANSIT',
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
                    distance: null,
                    duration: null,
                    costEstimate: null,
                    startTime: new Date(),
                    status: 'IN_TRANSIT',
                    productType: data.productType,
                    loadAmount: `${data.amount} ${data.unit}`,
                }
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
                    driver: driver.id,
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
                driver: driver.id,
            },
            orderBy: {
                createdAt: 'desc',
            },
        });

        const vehicleIds = Array.from(new Set(trips.map((trip) => trip.vehicle)));

        const [vehicles, vehicleTrips] = await Promise.all([
            prisma.vehicle.findMany({
                where: { id: { in: vehicleIds } },
                select: {
                    id: true,
                    registrationNumber: true,
                },
            }),
            prisma.vehicleTrip.findMany({
                where: { vehicleId: { in: vehicleIds } },
                select: {
                    vehicleId: true,
                    status: true,
                    loadAmount: true,
                    date: true,
                    distance: true,
                },
            }),
        ]);

        const vehicleById = new Map(vehicles.map((vehicle) => [vehicle.id, vehicle]));
        const tripByVehicleId = new Map(
            vehicleTrips.map((vehicleTrip) => [vehicleTrip.vehicleId, vehicleTrip]),
        );

        const enrichedTrips = trips.map((trip) => {
            const vehicle = vehicleById.get(trip.vehicle);
            const vehicleTrip = tripByVehicleId.get(trip.vehicle);

            return {
                ...trip,
                vehicleRegistrationNumber: vehicle?.registrationNumber ?? null,
                status: vehicleTrip?.status ?? 'PENDING',
                loadAmount: vehicleTrip?.loadAmount ?? null,
                tripDate: vehicleTrip?.date ?? trip.departureTime,
                tripDistance: vehicleTrip?.distance ?? null,
            };
        });

        return c.json({ trips: enrichedTrips });
    }
}
