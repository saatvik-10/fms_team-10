import type { Context } from 'hono';
import { createManagerSchema } from '../validators/manager.validator';
import { jwtAuth } from '../lib/jwt';
import { prisma } from '../../prisma';
import { hashPassword, comparePassword } from '../lib/hashPassword';
import { customAlphabet } from 'nanoid';

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

  async getManager(c: Context) {
    const body = await c.req.json();
    const { username, password } = body;

    const user = await prisma.user.findUnique({
      where: { username },
    });

    if (!user || user.role !== 'MANAGER') {
      return c.json({ err: 'Invalid credentials' }, 401);
    }

    const isPasswordValid = await comparePassword(password, user.passwordHash!);
    if (!isPasswordValid) {
      return c.json({ err: 'Invalid credentials' }, 401);
    }

    const token = await jwtAuth({
      userId: user.id,
      role: user.role,
    });

    return c.json({
      token,
      manager: {
        id: user.id,
        name: user.name,
      },
    });
  }
}