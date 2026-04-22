import type { Context } from 'hono';
import { createMaintenanceSchema } from '../validators/maintenance.validator';
import { nanoid } from 'nanoid';
import { prisma } from '../../prisma';
import { hashPassword } from '../lib/hashPassword';
import { sendCredentialsMail } from '../services/resend.service';

const notImplemented = (resource: string, action: string, id?: string) => {
  return { resource, action, ...(id ? { id } : {}) };
};

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

    const { name, email, phone, address, certification } = result.data;
    const managerId = c.get('userId') as string;

    const existingEmailUser = await prisma.user.findUnique({ where: { email } });
    if (existingEmailUser) {
      return c.json({ err: 'Email already in use' }, 409);
    }

    const existingMaintenance = await prisma.maintenance.findUnique({ where: { phone } });
    if (existingMaintenance) {
      return c.json({ err: 'Phone already in use' }, 409);
    }

    const firstName = name.split(' ')[0]!.toLowerCase();
    const username = `${firstName}_${nanoid(3)}`;
    const password = nanoid();
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
            email,
            phone,
            address,
            certification,
          },
        },
      },
      include: {
        maintenance: true,
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
          address: user.maintenance?.address,
          certification: user.maintenance?.certification,
          createdAt: user.maintenance?.createdAt,
        },
      },
      201,
    );
  }

  async getDashboard(c: Context) {
    return c.json(notImplemented('maintenance-dashboard', 'get'), 501);
  }

  async listWorkOrders(c: Context) {
    return c.json(notImplemented('work-orders', 'list'), 501);
  }

  async getWorkOrder(c: Context) {
    return c.json(notImplemented('work-orders', 'get', c.req.param('id')), 501);
  }

  async createWorkOrder(c: Context) {
    return c.json(notImplemented('work-orders', 'create'), 501);
  }

  async replaceWorkOrder(c: Context) {
    return c.json(notImplemented('work-orders', 'replace', c.req.param('id')), 501);
  }

  async updateWorkOrder(c: Context) {
    return c.json(notImplemented('work-orders', 'update', c.req.param('id')), 501);
  }

  async deleteWorkOrder(c: Context) {
    return c.json(notImplemented('work-orders', 'delete', c.req.param('id')), 501);
  }

  async listSchedules(c: Context) {
    return c.json(notImplemented('maintenance-schedules', 'list'), 501);
  }

  async getSchedule(c: Context) {
    return c.json(notImplemented('maintenance-schedules', 'get', c.req.param('id')), 501);
  }

  async createSchedule(c: Context) {
    return c.json(notImplemented('maintenance-schedules', 'create'), 501);
  }

  async replaceSchedule(c: Context) {
    return c.json(notImplemented('maintenance-schedules', 'replace', c.req.param('id')), 501);
  }

  async updateSchedule(c: Context) {
    return c.json(notImplemented('maintenance-schedules', 'update', c.req.param('id')), 501);
  }

  async deleteSchedule(c: Context) {
    return c.json(notImplemented('maintenance-schedules', 'delete', c.req.param('id')), 501);
  }

  async listInspections(c: Context) {
    return c.json(notImplemented('inspections', 'list'), 501);
  }

  async getInspection(c: Context) {
    return c.json(notImplemented('inspections', 'get', c.req.param('id')), 501);
  }

  async createInspection(c: Context) {
    return c.json(notImplemented('inspections', 'create'), 501);
  }

  async replaceInspection(c: Context) {
    return c.json(notImplemented('inspections', 'replace', c.req.param('id')), 501);
  }

  async updateInspection(c: Context) {
    return c.json(notImplemented('inspections', 'update', c.req.param('id')), 501);
  }

  async deleteInspection(c: Context) {
    return c.json(notImplemented('inspections', 'delete', c.req.param('id')), 501);
  }

  async listIssues(c: Context) {
    return c.json(notImplemented('issues', 'list'), 501);
  }

  async getIssue(c: Context) {
    return c.json(notImplemented('issues', 'get', c.req.param('id')), 501);
  }

  async replaceIssue(c: Context) {
    return c.json(notImplemented('issues', 'replace', c.req.param('id')), 501);
  }

  async updateIssue(c: Context) {
    return c.json(notImplemented('issues', 'update', c.req.param('id')), 501);
  }

  async listVehicles(c: Context) {
    return c.json(notImplemented('vehicles', 'list'), 501);
  }

  async getVehicle(c: Context) {
    return c.json(notImplemented('vehicles', 'get', c.req.param('id')), 501);
  }

  async updateVehicle(c: Context) {
    return c.json(notImplemented('vehicles', 'update', c.req.param('id')), 501);
  }

  async listNotifications(c: Context) {
    return c.json(notImplemented('notifications', 'list'), 501);
  }

  async updateNotification(c: Context) {
    return c.json(notImplemented('notifications', 'update', c.req.param('id')), 501);
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
}
