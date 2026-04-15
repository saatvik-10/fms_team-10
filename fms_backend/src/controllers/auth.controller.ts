import type { Context } from 'hono';
import { loginSchema, createManagerSchema } from '../validators/auth.validator';
import { jwtAuth } from '../lib/jwt';
import { prisma } from '../../prisma';
import { comparePassword, hashPassword } from '../lib/hashPassword';

const SUPER_ADMIN_EMAIL = process.env.SUPER_ADMIN_EMAIL;
const SUPER_ADMIN_PASSWORD = process.env.SUPER_ADMIN_PASSWORD;

export class Auth {
  async login(c: Context) {
    const body = await c.req.json();
    const result = loginSchema.safeParse(body);

    if (!result.success) {
      return c.json({ err: 'Invalid input' }, 400);
    }

    const { email, password } = result.data;

    let user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      const isDefaultSuperAdminLogin =
        email === SUPER_ADMIN_EMAIL && password === SUPER_ADMIN_PASSWORD;

      if (!isDefaultSuperAdminLogin) {
        return c.json({ err: 'Invalid super admin credentials' }, 401);
      }

      const passwordHash = await hashPassword(SUPER_ADMIN_PASSWORD);
      user = await prisma.user.create({
        data: {
          email: SUPER_ADMIN_EMAIL,
          passwordHash,
          role: 'SUPER_ADMIN',
        },
      });
    }

    if (user.role !== 'SUPER_ADMIN' || !user.passwordHash || !user.email) {
      return c.json({ err: 'Invalid super admin credentials' }, 401);
    }

    const isPasswordValid = await comparePassword(password, user.passwordHash);
    if (!isPasswordValid) {
      return c.json({ err: 'Invalid credentials' }, 401);
    }

    const token = await jwtAuth({
      userId: user.id,
      role: user.role,
    });

    return c.json({ token });
  }

  async getMe(c: Context) {
    return c.json({
      userId: c.get('userId'),
      role: c.get('role'),
    });
  }

  async createManager(c: Context) {
    const body = await c.req.json();
    const result = createManagerSchema.safeParse(body);

    if (!result.success) {
      return c.json(
        { err: 'Invalid input', details: result.error.flatten() },
        400,
      );
    }

    const { name, phone, address } = result.data;
    const superAdminId = c.get('userId');

    const existingUser = await prisma.user.findUnique({
      where: { phone },
    });

    if (existingUser) {
      return c.json({ err: 'Phone already in use' }, 409);
    }

    const manager = await prisma.user.create({
      data: {
        name,
        phone,
        address,
        role: 'MANAGER',
        createdById: superAdminId,
      },
    });

    return c.json(
      {
        message: 'Manager created successfully',
        manager: {
          id: manager.id,
          name: manager.name,
          phone: manager.phone,
          address: manager.address,
          role: manager.role,
        },
      },
      201,
    );
  }

  async signUp(c: Context) {
    return c.json({ err: 'Wrong manager creation endpoint' }, 400);
  }
}
