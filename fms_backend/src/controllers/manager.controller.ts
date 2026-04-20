import type { Context } from 'hono';
import { createManagerSchema } from '../validators/manager.validator';
import { prisma } from '../../prisma';
import { hashPassword } from '../lib/hashPassword';
import { customAlphabet } from 'nanoid';

const nanoid = customAlphabet(
  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*',
  10,
);

const notImplemented = (resource: string, action: string, id?: string) => {
  return { resource, action, ...(id ? { id } : {}) };
};

export class Manager {
  async createManager(c: Context) {
    const body = await c.req.json();
    const result = createManagerSchema.safeParse(body);

    if (!result.success) {
      return c.json(
        { err: 'Invalid input', details: result.error.flatten() },
        400,
      );
    }

    const { name, phone, address, email } = result.data;
    const superAdminId = c.get('userId');

    const existingUser = await prisma.user.findUnique({
      where: { phone },
    });

    if (existingUser) {
      return c.json({ err: 'Phone already in use' }, 409);
    }

    const firstName = name.split(' ')[0]!;
    const username = firstName.toLowerCase() + '_' + nanoid(3);
    const password = nanoid();
    const passwordHash = await hashPassword(password);

    const manager = await prisma.user.create({
      data: {
        name,
        username,
        phone,
        address,
        email,
        passwordHash,
        role: 'MANAGER',
        createdById: superAdminId,
      },
    });

    return c.json(
      {
        message: 'Manager created successfully',
        credentials: {
          username,
          password,
        },
        manager: {
          id: manager.id,
          name: manager.name,
        },
      },
      201,
    );
  }

  //   async getManagers(c: Context) {
  //     const managers = await prisma.user.findMany({
  //       where: { role: 'MANAGER' },
  //       select: {
  //         id: true,
  //         name: true,
  //         username: true,
  //         phone: true,
  //         address: true,
  //         email: true,
  //         createdAt: true,
  //       },
  //     });

  //     return c.json({ managers });
  //   }

  async getMyProfile(c: Context) {
    const userId = c.get('userId') as string;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        username: true,
        phone: true,
        address: true,
        email: true,
        role: true,
        createdAt: true,
      },
    });

    if (!user || user.role !== 'MANAGER') {
      return c.json({ err: 'Manager not found' }, 404);
    }

    return c.json({
      manager: user,
    });
  }

  async getManager(c: Context) {
    const userId = c.req.param('id');

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        username: true,
        phone: true,
        address: true,
        email: true,
        role: true,
        createdAt: true,
      },
    });

    if (!user || user.role !== 'MANAGER') {
      return c.json({ err: 'Manager not found' }, 404);
    }

    return c.json({
      manager: user,
    });
  }

  async listDrivers(c: Context) {
    return c.json(notImplemented('drivers', 'list'), 501);
  }

  async getDriver(c: Context) {
    return c.json(notImplemented('drivers', 'get', c.req.param('id')), 501);
  }

  async createDriver(c: Context) {
    return c.json(notImplemented('drivers', 'create'), 501);
  }

  async replaceDriver(c: Context) {
    return c.json(notImplemented('drivers', 'replace', c.req.param('id')), 501);
  }

  async updateDriver(c: Context) {
    return c.json(notImplemented('drivers', 'update', c.req.param('id')), 501);
  }

  async deleteDriver(c: Context) {
    return c.json(notImplemented('drivers', 'delete', c.req.param('id')), 501);
  }

  async listVehicles(c: Context) {
    return c.json(notImplemented('vehicles', 'list'), 501);
  }

  async getVehicle(c: Context) {
    return c.json(notImplemented('vehicles', 'get', c.req.param('id')), 501);
  }

  async createVehicle(c: Context) {
    return c.json(notImplemented('vehicles', 'create'), 501);
  }

  async replaceVehicle(c: Context) {
    return c.json(notImplemented('vehicles', 'replace', c.req.param('id')), 501);
  }

  async updateVehicle(c: Context) {
    return c.json(notImplemented('vehicles', 'update', c.req.param('id')), 501);
  }

  async deleteVehicle(c: Context) {
    return c.json(notImplemented('vehicles', 'delete', c.req.param('id')), 501);
  }

  async listAssignments(c: Context) {
    return c.json(notImplemented('assignments', 'list'), 501);
  }

  async getAssignment(c: Context) {
    return c.json(notImplemented('assignments', 'get', c.req.param('id')), 501);
  }

  async createAssignment(c: Context) {
    return c.json(notImplemented('assignments', 'create'), 501);
  }

  async replaceAssignment(c: Context) {
    return c.json(notImplemented('assignments', 'replace', c.req.param('id')), 501);
  }

  async updateAssignment(c: Context) {
    return c.json(notImplemented('assignments', 'update', c.req.param('id')), 501);
  }

  async deleteAssignment(c: Context) {
    return c.json(notImplemented('assignments', 'delete', c.req.param('id')), 501);
  }

  async listTrips(c: Context) {
    return c.json(notImplemented('trips', 'list'), 501);
  }

  async getTrip(c: Context) {
    return c.json(notImplemented('trips', 'get', c.req.param('id')), 501);
  }

  async createTrip(c: Context) {
    return c.json(notImplemented('trips', 'create'), 501);
  }

  async replaceTrip(c: Context) {
    return c.json(notImplemented('trips', 'replace', c.req.param('id')), 501);
  }

  async updateTrip(c: Context) {
    return c.json(notImplemented('trips', 'update', c.req.param('id')), 501);
  }

  async deleteTrip(c: Context) {
    return c.json(notImplemented('trips', 'delete', c.req.param('id')), 501);
  }

  async listNotifications(c: Context) {
    return c.json(notImplemented('notifications', 'list'), 501);
  }

  async createNotification(c: Context) {
    return c.json(notImplemented('notifications', 'create'), 501);
  }

  async updateNotification(c: Context) {
    return c.json(notImplemented('notifications', 'update', c.req.param('id')), 501);
  }

  async deleteNotification(c: Context) {
    return c.json(notImplemented('notifications', 'delete', c.req.param('id')), 501);
  }

  async listReports(c: Context) {
    return c.json(notImplemented('reports', 'list'), 501);
  }

  async getReport(c: Context) {
    return c.json(notImplemented('reports', 'get', c.req.param('id')), 501);
  }

  async createReport(c: Context) {
    return c.json(notImplemented('reports', 'create'), 501);
  }

  async updateReport(c: Context) {
    return c.json(notImplemented('reports', 'update', c.req.param('id')), 501);
  }

  async deleteReport(c: Context) {
    return c.json(notImplemented('reports', 'delete', c.req.param('id')), 501);
  }

  async listRoles(c: Context) {
    return c.json(notImplemented('roles', 'list'), 501);
  }

  async updateRole(c: Context) {
    return c.json(notImplemented('roles', 'update', c.req.param('id')), 501);
  }
}
