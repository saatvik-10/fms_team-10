import type { Context } from 'hono';
import { prisma } from '../../prisma';
import { createTripSchema } from '../validators/trip.validator';

export class Trip {
    async createTrip(c: Context) {
        const body = await c.req.json();
        const result = createTripSchema.safeParse(body);

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
            },
        });

        return c.json({ message: 'Trip created successfully', trip }, 201);
    }

    async getTrip(c: Context) {
        const tripId = c.req.query('id');

        if (!tripId) {
            return c.json({ err: 'Trip id is required as query param: ?id=' }, 400);
        }

        const trip = await prisma.trips.findUnique({
            where: {
                id: tripId,
            },
        });

        if (!trip) {
            return c.json({ err: 'Trip not found' }, 404);
        }

        return c.json({ trip });
    }

    async getTrips(c: Context) {
        const trips = await prisma.trips.findMany({
            orderBy: {
                createdAt: 'desc',
            },
        });

        return c.json({ trips });
    }
}