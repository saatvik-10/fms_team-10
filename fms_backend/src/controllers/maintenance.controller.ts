import type { Context } from 'hono';
import {
  createMaintenanceSchema,
  createWorkOrderSchema,
  updateMaintenanceSchema,
} from '../validators/maintenance.validator';
import { nanoid } from 'nanoid';
import { prisma } from '../../prisma';
import { WorkOrderStatus, VehicleStatus } from '../../generated/prisma';
import { hashPassword } from '../lib/hashPassword';
import { sendCredentialsMail } from '../services/resend.service';
import { calculateAge, decodeBase64Image, deleteUploadedKeys, getImageMeta } from '../lib/utils';
import { genPswd } from '../lib/genPswd';
import { R2Service } from '../services/r2.service';

const r2Service = new R2Service();

async function getMaintenanceFleetManagerId(userId: string) {
  const maintenance = await prisma.maintenance.findUnique({
    where: { userId },
    select: {
      id: true,
      user: {
        select: {
          createdById: true,
        },
      },
    },
  });

  if (!maintenance || !maintenance.user.createdById) {
    return null;
  }

  return {
    maintenanceId: maintenance.id,
    managerId: maintenance.user.createdById,
  };
}

async function getSignedWorkOrderMedia(mediaKeys: string[]) {
  if (!mediaKeys.length) {
    return [] as string[];
  }

  const signed = await Promise.allSettled(
    mediaKeys.map((key) => r2Service.getSignedDownloadUrl(key)),
  );

  return signed
    .map((item) => (item.status === 'fulfilled' ? item.value : null))
    .filter((item): item is string => Boolean(item));
}

function formatVehicleName(vehicle: { make: string; model: string; type: string; registrationNumber: string }) {
  return `${vehicle.make} ${vehicle.model} (${vehicle.type}) - ${vehicle.registrationNumber}`;
}

export class Maintenance {
  async createMaintenance(c: Context) {
    const body = await c.req.json();
    const result = createMaintenanceSchema.safeParse(body);

    if (!result.success) {
      return c.json(
        { err: 'Invalid input', details: result.error.flatten() },
        400,
      );
    }

    const { name, email, phone, dob } = result.data;
    const managerId = c.get('userId') as string;

    const existingEmailUser = await prisma.user.findUnique({
      where: { email },
      select: { id: true },
    });
    if (existingEmailUser) {
      return c.json({ err: 'Email already in use' }, 409);
    }

    const existingMaintenance = await prisma.maintenance.findUnique({
      where: { phone },
    });
    if (existingMaintenance) {
      return c.json({ err: 'Phone already in use' }, 409);
    }

    const firstName = name.split(' ')[0]!.toLowerCase();
    const username = `${firstName}_${nanoid(3)}`;
    const password = genPswd();
    const passwordHash = await hashPassword(password);

    // Create User and Maintenance in transaction
    const user = await prisma.user.create({
      data: {
        email,
        username,
        passwordHash,
        role: 'MAINTENANCE',
        createdById: managerId,
        maintenance: {
          create: {
            name,
            dob: new Date(dob),
            email,
            phone,
          },
        },
      },
      select: {
        username: true,
        maintenance: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            dob: true,
            createdAt: true,
          },
        },
      },
    });

    let mailStatus: { sent: boolean; details?: string } = { sent: true };

    try {
      await sendCredentialsMail({
        userEmail: email,
        role: 'Maintenance',
        username,
        password,
        senderRole: 'Manager',
      });
    } catch (error) {
      console.error('Failed to send maintenance credentials email', error);
      mailStatus = {
        sent: false,
        details: error instanceof Error ? error.message : 'Unknown mail error',
      };
    }

    return c.json(
      {
        message: 'Maintenance staff created successfully',
        credentials: {
          username,
          password,
        },
        mail: mailStatus,
        maintenance: {
          id: user.maintenance?.id,
          name: user.maintenance?.name,
          email: user.maintenance?.email,
          username: user.username,
          phone: user.maintenance?.phone,
          dob: user.maintenance?.dob,
          age: user.maintenance?.dob
            ? calculateAge(user.maintenance.dob)
            : null,
          createdAt: user.maintenance?.createdAt,
        },
      },
      201,
    );
  }

  async getMaintenances(c: Context) {
    const userId = c.get('userId') as string;

    const maintenances = await prisma.maintenance.findMany({
      where: {
        user: {
          createdById: userId,
        },
      },
      include: {
        user: {
          select: {
            username: true,
          },
        },
      },
    });

    return c.json({
      maintenances: maintenances.map((maintenance) => ({
        id: maintenance.id,
        name: maintenance.name,
        email: maintenance.email,
        username: maintenance.user.username,
        phone: maintenance.phone,
        dob: maintenance.dob,
        age: calculateAge(maintenance.dob),
        createdAt: maintenance.createdAt,
      })),
    });
  }

  async deleteMaintenance(c: Context) {
    const managerId = c.get('userId') as string;
    const maintenanceId = c.req.param('maintenanceId');

    if (!maintenanceId) {
      return c.json({ err: 'Maintenance id is required' }, 400);
    }

    const maintenance = await prisma.maintenance.findFirst({
      where: {
        id: maintenanceId,
        user: {
          createdById: managerId,
        },
      },
      select: {
        userId: true,
      },
    });

    if (!maintenance) {
      return c.json({ err: 'Maintenance profile not found' }, 404);
    }

    await prisma.$transaction([
      prisma.maintenance.delete({
        where: {
          id: maintenanceId,
        },
      }),
      prisma.user.delete({
        where: {
          id: maintenance.userId,
        },
      }),
    ]);

    return c.json({ message: 'Maintenance profile deleted successfully' });
  }

  async updateMaintenance(c: Context) {
    const managerId = c.get('userId') as string;
    const maintenanceId = c.req.param('maintenanceId');

    if (!maintenanceId) {
      return c.json({ err: 'Maintenance id is required' }, 400);
    }

    const body = await c.req.json();
    const result = updateMaintenanceSchema.safeParse(body);

    if (!result.success) {
      return c.json(
        { err: 'Invalid input', details: result.error.flatten() },
        400,
      );
    }

    const { name, email, phone, dob } = result.data;

    const existingMaintenance = await prisma.maintenance.findFirst({
      where: {
        id: maintenanceId,
        user: {
          createdById: managerId,
        },
      },
      include: {
        user: {
          select: {
            id: true,
            email: true,
          },
        },
      },
    });

    if (!existingMaintenance) {
      return c.json({ err: 'Maintenance profile not found' }, 404);
    }

    if (email && email !== existingMaintenance.email) {
      const existingEmail = await prisma.user.findUnique({
        where: { email },
      });
      if (existingEmail) {
        return c.json({ err: 'Email already in use' }, 409);
      }
    }

    if (phone && phone !== existingMaintenance.phone) {
      const existingPhone = await prisma.maintenance.findUnique({
        where: { phone },
      });
      if (existingPhone) {
        return c.json({ err: 'Phone already in use' }, 409);
      }
    }

    const updateData: {
      name?: string;
      email?: string;
      phone?: string;
      dob?: Date;
      user?: {
        update: {
          email?: string;
        };
      };
    } = {};

    if (name) updateData.name = name;
    if (phone) updateData.phone = phone;
    if (dob) updateData.dob = new Date(dob);
    if (email) {
      updateData.email = email;
      updateData.user = {
        update: {
          email,
        },
      };
    }

    const updated = await prisma.maintenance.update({
      where: {
        id: maintenanceId,
      },
      data: updateData,
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        dob: true,
        createdAt: true,
      },
    });

    return c.json({
      message: 'Maintenance profile updated successfully',
      maintenance: {
        ...updated,
        age: calculateAge(updated.dob),
      },
    });
  }

  async getWorkOrderVehicles(c: Context) {
    const userId = c.get('userId') as string;
    const ownership = await getMaintenanceFleetManagerId(userId);

    if (!ownership) {
      return c.json({ err: 'Maintenance profile not found' }, 404);
    }

    const vehicles = await prisma.vehicle.findMany({
      where: {
        createdById: ownership.managerId,
      },
      orderBy: {
        createdAt: 'desc',
      },
      select: {
        id: true,
        make: true,
        model: true,
        type: true,
        status: true,
        year: true,
        color: true,
        chassisNumber: true,
        registrationNumber: true,
      },
    });

    return c.json({
      vehicles: vehicles.map((vehicle) => ({
        ...vehicle,
        displayName: formatVehicleName(vehicle),
      })),
    });
  }

  async createWorkOrder(c: Context) {
    const body = await c.req.json();
    const result = createWorkOrderSchema.safeParse(body);

    if (!result.success) {
      return c.json(
        { err: 'Invalid input', details: result.error.flatten() },
        400,
      );
    }

    const userId = c.get('userId') as string;
    const ownership = await getMaintenanceFleetManagerId(userId);

    if (!ownership) {
      return c.json({ err: 'Maintenance profile not found' }, 404);
    }

    const { vehicleId, title, serviceType, priority, date, taskDetails, mediaImages } = result.data;

    const vehicle = await prisma.vehicle.findFirst({
      where: {
        id: vehicleId,
        createdById: ownership.managerId,
      },
      select: {
        id: true,
        make: true,
        model: true,
        type: true,
        registrationNumber: true,
      },
    });

    if (!vehicle) {
      return c.json({ err: 'Vehicle not found for this maintenance profile' }, 404);
    }

    const workOrder = await prisma.workOrder.create({
      data: {
        vehicleId: vehicle.id,
        vehicleName: vehicle.model,
        vehicleNum: vehicle.registrationNumber,
        title,
        serviceType,
        priority,
        date: new Date(date),
        taskDetails,
        workOrderMedia: [],
        maintenanceId: ownership.maintenanceId,
      },
    });

    const uploadedKeys: string[] = [];

    try {
      for (let index = 0; index < mediaImages.length; index += 1) {
        const image = mediaImages[index]!;
        const { contentType, extension } = getImageMeta(image);

        const uploaded = await r2Service.uploadByScope({
          scope: {
            role: 'maintenanceWorkOrder',
            userId,
            workOrderId: workOrder.id,
          },
          fileName: `work_order_${index + 1}_${nanoid(4)}.${extension}`,
          body: decodeBase64Image(image),
          contentType,
        });

        uploadedKeys.push(uploaded.key);
      }

      const savedWorkOrder = uploadedKeys.length
        ? await prisma.workOrder.update({
          where: { id: workOrder.id },
          data: { workOrderMedia: uploadedKeys },
        })
        : workOrder;

      return c.json(
        {
          message: 'Work order created successfully',
          workOrder: {
            ...savedWorkOrder,
            mediaUrls: await getSignedWorkOrderMedia(savedWorkOrder.workOrderMedia),
          },
        },
        201,
      );
    } catch (error) {
      await deleteUploadedKeys(uploadedKeys);
      await prisma.workOrder.delete({ where: { id: workOrder.id } }).catch(() => null);
      throw error;
    }
  }

  async getWorkOrders(c: Context) {
    const userId = c.get('userId') as string;
    const ownership = await getMaintenanceFleetManagerId(userId);

    if (!ownership) {
      return c.json({ err: 'Maintenance profile not found' }, 404);
    }

    const status = c.req.query('status');

    const workOrders = await prisma.workOrder.findMany({
      where: {
        maintenanceId: ownership.maintenanceId,
        ...(status ? { status: status.toUpperCase() } : {}),
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    const hydrated = await Promise.all(
      workOrders.map(async (workOrder) => ({
        ...workOrder,
        mediaUrls: await getSignedWorkOrderMedia(workOrder.workOrderMedia),
      })),
    );

    return c.json({ workOrders: hydrated });
  }

  async completeWorkOrder(c: Context) {
    const userId = c.get('userId') as string;
    const workOrderId = c.req.param('id');
    const { totalCost, technicianNotes, checklist, isEmergency, odometer, fuelLevel, consumedParts, workOrderMedia, taskDetails } = await c.req.json();

    const ownership = await getMaintenanceFleetManagerId(userId);

    if (!ownership) {
      return c.json({ err: 'Maintenance profile not found' }, 404);
    }

    const workOrder = await prisma.workOrder.findFirst({
      where: {
        id: workOrderId,
        maintenanceId: ownership.maintenanceId,
      },
      include: {
        vehicle: true,
      }
    });

    if (!workOrder) {
      return c.json({ err: 'Work order not found or unauthorized' }, 404);
    }

    const uploadedMediaKeys: string[] = [];
    if (workOrderMedia && Array.isArray(workOrderMedia)) {
      for (const media of workOrderMedia) {
        if (media.startsWith('data:image') || media.length > 500) {
          try {
            const upload = await r2Service.uploadByScope({
              scope: {
                role: 'maintenance',
                userId,
                vehicleId: '',
              },
              fileName: `${workOrderId}_evidence_${nanoid(4)}.jpg`,
              body: decodeBase64Image(media),
              contentType: 'image/jpeg',
            });
            uploadedMediaKeys.push(upload.key);
          } catch (e) {
            console.error('Failed to upload image', e);
          }
        } else {
          uploadedMediaKeys.push(media);
        }
      }
    }

    const updatedMedia = [...(workOrder.workOrderMedia || []), ...uploadedMediaKeys];

    const updatedWorkOrder = await prisma.workOrder.update({
      where: { id: workOrderId },
      data: {
        status: WorkOrderStatus.COMPLETED,
        totalCost: Number(totalCost) || 0,
        workOrderMedia: updatedMedia,
      },
    });

    if (updatedWorkOrder.vehicleId) {
      const nextStatus = updatedWorkOrder.tripId ? VehicleStatus.SCHEDULED : VehicleStatus.AVAILABLE;
      await prisma.vehicle.update({
        where: { id: updatedWorkOrder.vehicleId },
        data: { status: nextStatus },
      });
    }

    // Automatically create an Inspection record based on the completed Work Order
    const vehicleName = workOrder.vehicleName || 'Unknown Vehicle';
    const isBus = vehicleName.toLowerCase().includes('bus');

    await prisma.inspection.create({
      data: {
        workOrderId: workOrder.id,
        title: workOrder.title,
        vehicleId: workOrder.vehicleId || '-',
        unitName: vehicleName,
        unitVIN: workOrder.vehicleId || '-',
        driverId: 'N/A',
        timestamp: new Date(),
        type: 'Pre-Trip',
        vehicleType: isBus ? 'Car' : 'Truck',
        status: 'Completed',
        priority: workOrder.priority,
        items: checklist || [],
        notes: technicianNotes || '',
        taskDetails: taskDetails || workOrder.taskDetails || '',
        maintenanceStaffId: workOrder.maintenanceId,
        isEmergency: isEmergency || false,
        odometer: odometer || 'N/A',
        fuelLevel: fuelLevel || 'N/A',
        imageUrls: updatedMedia,
        consumedParts: consumedParts || [],
        maintenanceId: ownership.maintenanceId,
      }
    });

    if (updatedWorkOrder.vehicleId && updatedWorkOrder.totalCost > 0) {
      await prisma.vehicle.update({
        where: { id: updatedWorkOrder.vehicleId },
        data: {
          totalMaintenanceCost: {
            increment: updatedWorkOrder.totalCost,
          },
        },
      });
    }

    return c.json({ message: 'Work order completed successfully', workOrder: updatedWorkOrder });
  }

  async getInspections(c: Context) {
    const userId = c.get('userId') as string;
    const ownership = await getMaintenanceFleetManagerId(userId);

    if (!ownership) {
      return c.json({ err: 'Maintenance profile not found' }, 404);
    }

    const inspections = await prisma.inspection.findMany({
      where: {
        maintenanceId: ownership.maintenanceId,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    const hydrated = await Promise.all(
      inspections.map(async (insp) => ({
        ...insp,
        imageUrls: await getSignedWorkOrderMedia(insp.imageUrls),
      })),
    );

    return c.json({ inspections: hydrated });
  }

  async updateInspection(c: Context) {
    const userId = c.get('userId') as string;
    const inspectionId = c.req.param('id');
    const updates = await c.req.json();

    const ownership = await getMaintenanceFleetManagerId(userId);
    if (!ownership) {
      return c.json({ err: 'Maintenance profile not found' }, 404);
    }

    const existing = await prisma.inspection.findFirst({
      where: {
        id: inspectionId,
        maintenanceId: ownership.maintenanceId,
      },
    });

    if (!existing) {
      return c.json({ err: 'Inspection not found' }, 404);
    }

    const updated = await prisma.inspection.update({
      where: { id: inspectionId },
      data: {
        notes: updates.notes ?? existing.notes,
        items: updates.items ?? existing.items,
        reportUrl: updates.reportUrl ?? existing.reportUrl,
      },
    });

    return c.json({ message: 'Inspection updated successfully', inspection: updated });
  }
}
