import type { Context } from 'hono';
import { createMaintenanceSchema } from '../validators/maintenance.validator';
import { nanoid } from 'nanoid';
import { prisma } from '../../prisma';
import { hashPassword } from '../lib/hashPassword';
import { sendCredentialsMail } from '../services/resend.service';
import { calculateAge } from '../lib/utils';
import { genPswd } from '../lib/genPswd';

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
}
