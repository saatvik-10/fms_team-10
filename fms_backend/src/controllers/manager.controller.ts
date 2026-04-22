import type { Context } from 'hono';
import { createManagerSchema } from '../validators/manager.validator';
import { createDriverSchema } from '../validators/driver.validator';
import { sendCredentialsMail } from '../services/resend.service';
import { prisma } from '../../prisma';
import { hashPassword } from '../lib/hashPassword';
import { customAlphabet } from 'nanoid';
import { createVehicleSchema } from '../validators/vehicle.validator';

const nanoid = customAlphabet(
  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*',
  10,
);

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

    // Check if email is already used in any user
    const existingEmailUser = await prisma.user.findUnique({
      where: { email },
    });

    if (existingEmailUser) {
      return c.json({ err: 'Email already in use' }, 409);
    }

    // Check if phone is already used in manager
    const existingManager = await prisma.manager.findUnique({
      where: { phone },
    });

    if (existingManager) {
      return c.json({ err: 'Phone already in use' }, 409);
    }

    const firstName = name.split(' ')[0]!;
    const username = firstName.toLowerCase() + '_' + nanoid(3);
    const password = nanoid();
    const passwordHash = await hashPassword(password);

    // Create User and Manager in transaction
    const user = await prisma.user.create({
      data: {
        username,
        email,
        passwordHash,
        role: 'MANAGER',
        createdById: superAdminId,
        manager: {
          create: {
            name,
            phone,
            address,
          },
        },
      },
      include: {
        manager: true,
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
          id: user.manager?.id,
          name: user.manager?.name,
        },
      },
      201,
    );
  }

  async getManager(c: Context) {
    const managerId = c.req.param('id');

    const manager = await prisma.manager.findUnique({
      where: { id: managerId },
      include: {
        user: true,
      },
    });

    if (!manager) {
      return c.json({ err: 'Manager not found' }, 404);
    }

    return c.json({
      manager: {
        id: manager.id,
        name: manager.name,
        email: manager.user.email,
        username: manager.user.username,
        phone: manager.phone,
        address: manager.address,
        role: manager.user.role,
        createdAt: manager.createdAt,
      },
    });
  }
}
