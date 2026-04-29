import type { Context } from 'hono';
import { prisma } from '../../prisma';
import {
  createVehicleSchema,
  type CreateVehicleType,
  updateVehicleSchema,
  type UpdateVehicleType,
  tripHistorySchema,
  type TripHistoryType,
  currentTripSchema,
  type CurrentTripType,
  vehicleMaintenanceSchema,
  type VehicleMaintenanceType,
} from '../validators/vehicle.validator';
import { R2Service } from '../services/r2.service';
import { nanoid } from 'nanoid';
import {
  decodeBase64Image,
  extractKeyFromUrl,
  deleteUploadedKeys,
} from '../lib/utils';

const r2Service = new R2Service();

async function getFreshSignedUrl(
  key: string | null | undefined,
  fallbackUrl: string | null | undefined,
) {
  const objectKey = key ?? extractKeyFromUrl(fallbackUrl);
  return objectKey ? r2Service.getSignedDownloadUrl(objectKey) : null;
}

async function uploadVehicleImage(params: {
  managerId: string;
  registrationNum: string;
  kind: 'rc' | 'vehicle';
  imageData: string;
}) {
  const upload = await r2Service.uploadByScope({
    scope: {
      role: 'manager',
      userId: params.managerId,
      documentType: params.kind,
    },
    fileName: `${params.registrationNum.toLowerCase().replace(/[^a-z0-9]/g, '_')}_${params.kind}_${nanoid(4)}.jpg`,
    body: decodeBase64Image(params.imageData),
    contentType: 'image/jpeg',
  });

  const url = await r2Service.getSignedDownloadUrl(upload.key);
  return { key: upload.key, url };
}

export class Vehicle {
  async createVehicle(c: Context) {
    const body = await c.req.json();
    const result = createVehicleSchema.safeParse(body);

    if (!result.success) {
      return c.json(
        { err: 'Invalid input', details: result.error.flatten() },
        400,
      );
    }

    const data = result.data as CreateVehicleType;
    const userId = c.get('userId') as string;

    const existingByRegistration = await prisma.vehicle.findUnique({
      where: { registrationNumber: data.registrationNumber },
      select: { id: true },
    });

    if (existingByRegistration) {
      return c.json({ err: 'Registration number already in use' }, 409);
    }

    const existingByChassis = await prisma.vehicle.findUnique({
      where: { chassisNumber: data.chassisNumber },
      select: { id: true },
    });

    if (existingByChassis) {
      return c.json({ err: 'Chassis number already in use' }, 409);
    }

    let rcUrl: string | null = null;
    let vehicleImgUrl: string | null = null;
    let rcKey: string | null = null;
    let vehicleKey: string | null = null;

    if (data.rcDocumentImage) {
      const rcUpload = await uploadVehicleImage({
        managerId: userId,
        registrationNum: data.registrationNumber,
        kind: 'rc',
        imageData: data.rcDocumentImage,
      });
      rcUrl = rcUpload.url;
      rcKey = rcUpload.key;
    }

    if (data.vehicleImage) {
      const vehicleUpload = await uploadVehicleImage({
        managerId: userId,
        registrationNum: data.registrationNumber,
        kind: 'vehicle',
        imageData: data.vehicleImage,
      });
      vehicleImgUrl = vehicleUpload.url;
      vehicleKey = vehicleUpload.key;
    }

    try {
      const vehicle = await prisma.vehicle.create({
        data: {
          make: data.make,
          model: data.model,
          type: data.type,
          status: data.status ?? 'AVAILABLE',
          imageName: data.imageName,
          year: data.year,
          color: data.color,
          operationalStatus: data.operationalStatus ?? 'OPERATIONAL',
          assessmentReason: data.assessmentReason,
          chassisNumber: data.chassisNumber,
          registrationNumber: data.registrationNumber,
          rcImageUrl: rcUrl,
          vehicleImageUrl: vehicleImgUrl,
          rcImageKey: rcKey,
          vehicleImageKey: vehicleKey,
          maxLoadCapacity: data.maxLoadCapacity,
          capacityUnit: data.capacityUnit,
          createdById: userId,
        },
      });

      return c.json({ message: 'Vehicle created successfully', vehicle }, 201);
    } catch (error) {
      await deleteUploadedKeys([rcKey, vehicleKey]);
      throw error;
    }
  }

  async updateVehicle(c: Context) {
    const vehicleId = c.req.param('vehicleId');
    const body = await c.req.json();
    const result = updateVehicleSchema.safeParse(body);

    if (!result.success) {
      return c.json(
        { err: 'Invalid input', details: result.error.flatten() },
        400,
      );
    }

    const data = result.data as UpdateVehicleType;
    const userId = c.get('userId') as string;

    const existingVehicle = await prisma.vehicle.findFirst({
      where: {
        id: vehicleId,
        createdById: userId,
      },
      select: {
        id: true,
        registrationNumber: true,
        chassisNumber: true,
        rcImageUrl: true,
        vehicleImageUrl: true,
        rcImageKey: true,
        vehicleImageKey: true,
      },
    });

    if (!existingVehicle) {
      return c.json({ err: 'Vehicle not found' }, 404);
    }

    if (
      data.registrationNumber &&
      data.registrationNumber !== existingVehicle.registrationNumber
    ) {
      const existingByRegistration = await prisma.vehicle.findUnique({
        where: { registrationNumber: data.registrationNumber },
        select: { id: true },
      });

      if (existingByRegistration) {
        return c.json({ err: 'Registration number already in use' }, 409);
      }
    }

    if (
      data.chassisNumber &&
      data.chassisNumber !== existingVehicle.chassisNumber
    ) {
      const existingByChassis = await prisma.vehicle.findUnique({
        where: { chassisNumber: data.chassisNumber },
        select: { id: true },
      });

      if (existingByChassis) {
        return c.json({ err: 'Chassis number already in use' }, 409);
      }
    }

    let nextRcImageUrl = existingVehicle.rcImageUrl;
    let nextVehicleImageUrl = existingVehicle.vehicleImageUrl;
    let newRcKey: string | null = null;
    let newVehicleKey: string | null = null;

    try {
      const effectiveRegistration =
        data.registrationNumber ?? existingVehicle.registrationNumber;

      if (data.rcDocumentImage) {
        const rcUpload = await uploadVehicleImage({
          managerId: userId,
          registrationNum: effectiveRegistration,
          kind: 'rc',
          imageData: data.rcDocumentImage,
        });
        nextRcImageUrl = rcUpload.url;
        newRcKey = rcUpload.key;
      }

      if (data.vehicleImage) {
        const vehicleUpload = await uploadVehicleImage({
          managerId: userId,
          registrationNum: effectiveRegistration,
          kind: 'vehicle',
          imageData: data.vehicleImage,
        });
        nextVehicleImageUrl = vehicleUpload.url;
        newVehicleKey = vehicleUpload.key;
      }

      const vehicle = await prisma.vehicle.update({
        where: { id: existingVehicle.id },
        data: {
          ...(data.make ? { make: data.make } : {}),
          ...(data.model ? { model: data.model } : {}),
          ...(data.type ? { type: data.type } : {}),
          ...(data.status ? { status: data.status } : {}),
          ...(data.imageName ? { imageName: data.imageName } : {}),
          ...(data.year ? { year: data.year } : {}),
          ...(data.color ? { color: data.color } : {}),
          ...(data.operationalStatus
            ? { operationalStatus: data.operationalStatus }
            : {}),
          ...(data.assessmentReason
            ? { assessmentReason: data.assessmentReason }
            : {}),
          ...(data.chassisNumber ? { chassisNumber: data.chassisNumber } : {}),
          ...(data.registrationNumber
            ? { registrationNumber: data.registrationNumber }
            : {}),
          ...(data.assignedDriverId
            ? { assignedDriverId: data.assignedDriverId }
            : {}),
          ...(data.maxLoadCapacity !== undefined
            ? { maxLoadCapacity: data.maxLoadCapacity }
            : {}),
          ...(data.capacityUnit ? { capacityUnit: data.capacityUnit } : {}),
          rcImageUrl: nextRcImageUrl,
          vehicleImageUrl: nextVehicleImageUrl,
          rcImageKey: newRcKey ?? existingVehicle.rcImageKey,
          vehicleImageKey: newVehicleKey ?? existingVehicle.vehicleImageKey,
        },
      });

      await deleteUploadedKeys([
        newRcKey ? extractKeyFromUrl(existingVehicle.rcImageUrl) : null,
        newVehicleKey
          ? extractKeyFromUrl(existingVehicle.vehicleImageUrl)
          : null,
      ]);

      return c.json({ message: 'Vehicle updated successfully', vehicle });
    } catch (error) {
      await deleteUploadedKeys([newRcKey, newVehicleKey]);
      throw error;
    }
  }

  async deleteVehicle(c: Context) {
    const vehicleId = c.req.param('vehicleId');
    const userId = c.get('userId') as string;

    const vehicle = await prisma.vehicle.findFirst({
      where: {
        id: vehicleId,
        createdById: userId,
      },
      select: {
        id: true,
        rcImageUrl: true,
        vehicleImageUrl: true,
        status: true,
      },
    });

    if (!vehicle) {
      return c.json({ err: 'Vehicle not found' }, 404);
    }

    if (vehicle.status !== 'AVAILABLE') {
      return c.json(
        {
          err: 'Vehicle can only be deleted when its status is AVAILABLE (IDLE)',
        },
        400,
      );
    }

    await prisma.$transaction([
      prisma.vehicleTrip.deleteMany({ where: { vehicleId: vehicle.id } }),
      prisma.vehicleMaintenance.deleteMany({
        where: { vehicleId: vehicle.id },
      }),
      prisma.tripHistory.deleteMany({ where: { vehicleId: vehicle.id } }),
      prisma.vehicle.delete({ where: { id: vehicle.id } }),
    ]);

    await deleteUploadedKeys([
      extractKeyFromUrl(vehicle.rcImageUrl),
      extractKeyFromUrl(vehicle.vehicleImageUrl),
    ]);

    return c.json({ message: 'Vehicle deleted successfully' });
  }

  async getVehicles(c: Context) {
    const userId = c.get('userId') as string;
    const role = c.get('role') as string | undefined;
    let ownerId = userId;

    if (role === 'MAINTENANCE') {
      const maintenance = await prisma.maintenance.findUnique({
        where: { userId },
        select: {
          user: {
            select: {
              createdById: true,
            },
          },
        },
      });

      if (!maintenance?.user.createdById) {
        return c.json({ err: 'Maintenance profile not found' }, 404);
      }

      ownerId = maintenance.user.createdById;
    }

    const vehicles = await prisma.vehicle.findMany({
      where: {
        createdById: ownerId,
      },
    });

    const vehiclesWithRelations = await Promise.all(
      vehicles.map(async (v) => {
        const [currentTrip, maintenance, driver] = await Promise.all([
          prisma.vehicleTrip.findUnique({ where: { vehicleId: v.id } }),
          prisma.vehicleMaintenance.findUnique({ where: { vehicleId: v.id } }),
          v.assignedDriverId
            ? prisma.driver.findUnique({
              where: { id: v.assignedDriverId },
              select: {
                id: true,
                name: true,
                phone: true,
                status: true,
                licenceNumber: true,
                classes: true,
              },
            })
            : Promise.resolve(null),
        ]);

        const latestStoredTrip = await prisma.trips.findFirst({
          where: {
            createdById: ownerId,
            vehicleId: v.id,
          },
          orderBy: { createdAt: 'desc' },
          include: {
            driver: {
              select: {
                id: true,
                name: true,
                phone: true,
                status: true,
                licenceNumber: true,
                classes: true,
              },
            },
          },
        });

        const assignedDriver = driver ?? latestStoredTrip?.driver ?? null;

        const hydratedCurrentTrip =
          currentTrip ??
          (latestStoredTrip
            ? {
              id: latestStoredTrip.id,
              vehicleId: v.id,
              origin: latestStoredTrip.sourceLocation,
              destination: latestStoredTrip.destinationLocation,
              progress: 0.0,
              eta: null,
              date: latestStoredTrip.departureTime,
              distance: null,
              duration: null,
              costEstimate: null,
              startTime: latestStoredTrip.createdAt,
              status: 'IN_TRANSIT',
              productType: latestStoredTrip.productType,
              loadAmount: `${latestStoredTrip.amount} ${latestStoredTrip.unit}`,
              createdAt: latestStoredTrip.createdAt,
              updatedAt: latestStoredTrip.updatedAt,
            }
            : null);

        const vehicleImageUrl = await getFreshSignedUrl(
          v.vehicleImageKey,
          v.vehicleImageUrl,
        );
        const rcImageUrl = await getFreshSignedUrl(v.rcImageKey, v.rcImageUrl);

        return {
          ...v,
          status:
            hydratedCurrentTrip?.status === 'IN_TRANSIT'
              ? 'IN_TRANSIT'
              : v.status,
          vehicleImageUrl,
          rcImageUrl,
          currentTrip: hydratedCurrentTrip,
          maintenance,
          assignedDriver,
        };
      }),
    );

    return c.json({
      vehicles: vehiclesWithRelations,
    });
  }

  async getVehicleById(c: Context) {
    const vehicleId = c.req.param('vehicleId');
    const userId = c.get('userId') as string;

    const vehicle = await prisma.vehicle.findFirst({
      where: {
        id: vehicleId,
        createdById: userId,
      },
    });

    if (!vehicle) {
      return c.json({ err: 'Vehicle not found' }, 404);
    }

    vehicle.rcImageUrl = await getFreshSignedUrl(
      vehicle.rcImageKey,
      vehicle.rcImageUrl,
    );
    vehicle.vehicleImageUrl = await getFreshSignedUrl(
      vehicle.vehicleImageKey,
      vehicle.vehicleImageUrl,
    );

    const [currentTrip, maintenance, driver, history] = await Promise.all([
      prisma.vehicleTrip.findUnique({ where: { vehicleId: vehicle.id } }),
      prisma.vehicleMaintenance.findUnique({
        where: { vehicleId: vehicle.id },
      }),
      vehicle.assignedDriverId
        ? prisma.driver.findUnique({
          where: { id: vehicle.assignedDriverId },
          select: {
            id: true,
            name: true,
            phone: true,
            status: true,
            licenceNumber: true,
            classes: true,
          },
        })
        : Promise.resolve(null),
      prisma.tripHistory.findMany({
        where: { vehicleId: vehicle.id },
        orderBy: { createdAt: 'desc' },
        take: 10,
      }),
    ]);

    return c.json({
      vehicle: {
        ...vehicle,
        currentTrip,
        maintenance,
        assignedDriver: driver,
      },
      history,
    });
  }

  async updateCurrentTrip(c: Context) {
    const vehicleId = c.req.param('vehicleId');
    const body = await c.req.json();
    const result = currentTripSchema.safeParse(body);

    if (!result.success) {
      return c.json(
        { err: 'Invalid input', details: result.error.flatten() },
        400,
      );
    }

    const data = result.data as CurrentTripType;
    const userId = c.get('userId') as string;

    const vehicle = await prisma.vehicle.findFirst({
      where: {
        id: vehicleId,
        createdById: userId,
      },
      select: { id: true },
    });

    if (!vehicle) {
      return c.json({ err: 'Vehicle not found' }, 404);
    }

    const trip = await prisma.vehicleTrip.upsert({
      where: { vehicleId: vehicle.id },
      create: {
        vehicleId: vehicle.id,
        origin: data.origin,
        destination: data.destination,
        progress: data.progress,
        eta: data.eta,
        date: data.date,
        distance: data.distance,
        duration: data.duration,
        costEstimate: data.costEstimate,
        startTime: data.startTime ? new Date(data.startTime) : null,
        status: data.status ?? 'PENDING',
        productType: data.productType,
        loadAmount: data.loadAmount,
      },
      update: {
        origin: data.origin,
        destination: data.destination,
        progress: data.progress,
        eta: data.eta,
        date: data.date,
        distance: data.distance,
        duration: data.duration,
        costEstimate: data.costEstimate,
        startTime: data.startTime ? new Date(data.startTime) : null,
        status: data.status ?? 'PENDING',
        productType: data.productType,
        loadAmount: data.loadAmount,
      },
    });

    if (data.status === 'COMPLETED') {
      await prisma.vehicle.update({
        where: { id: vehicle.id },
        data: { status: 'AVAILABLE' },
      });
    } else if (data.status === 'IN_TRANSIT') {
      await prisma.vehicle.update({
        where: { id: vehicle.id },
        data: { status: 'IN_TRANSIT' },
      });
    }

    return c.json({ message: 'Trip updated successfully', trip });
  }

  async updateMaintenance(c: Context) {
    const vehicleId = c.req.param('vehicleId');
    const body = await c.req.json();
    const result = vehicleMaintenanceSchema.safeParse(body);

    if (!result.success) {
      return c.json(
        { err: 'Invalid input', details: result.error.flatten() },
        400,
      );
    }

    const data = result.data as VehicleMaintenanceType;
    const userId = c.get('userId') as string;

    const vehicle = await prisma.vehicle.findFirst({
      where: {
        id: vehicleId,
        createdById: userId,
      },
      select: { id: true },
    });

    if (!vehicle) {
      return c.json({ err: 'Vehicle not found' }, 404);
    }

    const maintenance = await prisma.vehicleMaintenance.upsert({
      where: { vehicleId: vehicle.id },
      create: {
        vehicleId: vehicle.id,
        nextService: data.nextService,
        inspectionStatus: data.inspectionStatus,
        alerts: data.alerts,
      },
      update: {
        nextService: data.nextService,
        inspectionStatus: data.inspectionStatus,
        alerts: data.alerts,
      },
    });

    return c.json({ message: 'Maintenance updated successfully', maintenance });
  }

  async addTripHistory(c: Context) {
    const vehicleId = c.req.param('vehicleId');
    const body = await c.req.json();
    const result = tripHistorySchema.safeParse(body);

    if (!result.success) {
      return c.json(
        { err: 'Invalid input', details: result.error.flatten() },
        400,
      );
    }

    const data = result.data as TripHistoryType;
    const userId = c.get('userId') as string;

    const vehicle = await prisma.vehicle.findFirst({
      where: {
        id: vehicleId,
        createdById: userId,
      },
      select: { id: true },
    });

    if (!vehicle) {
      return c.json({ err: 'Vehicle not found' }, 404);
    }

    const history = await prisma.tripHistory.create({
      data: {
        vehicleId: vehicle.id,
        vehicleID: data.vehicleID,
        origin: data.origin,
        destination: data.destination,
        progress: data.progress,
        eta: data.eta,
        date: data.date,
        distance: data.distance,
        duration: data.duration,
        costEstimate: data.costEstimate,
        startTime: data.startTime ? new Date(data.startTime) : null,
        status: data.status ?? 'PENDING',
        productType: data.productType,
        loadAmount: data.loadAmount,
      },
    });

    return c.json({ message: 'Trip history added successfully', history }, 201);
  }

  async getTripHistory(c: Context) {
    const vehicleId = c.req.param('vehicleId');
    const userId = c.get('userId') as string;

    const vehicle = await prisma.vehicle.findFirst({
      where: {
        id: vehicleId,
        createdById: userId,
      },
      select: { id: true },
    });

    if (!vehicle) {
      return c.json({ err: 'Vehicle not found' }, 404);
    }

    const history = await prisma.tripHistory.findMany({
      where: { vehicleId: vehicle.id },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });

    return c.json({ history });
  }
}
