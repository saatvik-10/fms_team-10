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

        const trip = await prisma.trips.create({
            data: {
                sourceLocation: data.sourceLocation,
                destinationLocation: data.destinationLocation,
                productType: data.productType,
                unit: data.unit,
                amount: data.amount,
                vehicle: data.vehicle,
                driver: data.driver,
                departureTime: data.departureTime,
                createdById: userId,
            },
        });

        return c.json({ message: 'Trip created successfully', trip }, 201);
    }

    async getTrip(c: Context) {
        const tripId = c.req.query('id');
        const userId = c.get('userId') as string;

        if (!tripId) {
            return c.json({ err: 'Trip id is required as query param: ?id=' }, 400);
        }

        const trip = await prisma.trips.findFirst({
            where: {
                id: tripId,
                createdById: userId,
            },
        });

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
}