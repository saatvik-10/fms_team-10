import type { Context } from 'hono';
import { loginSchema, managerLoginSchema } from '../validators/auth.validator';
import { jwtAuth } from '../lib/jwt';
import { prisma } from '../../prisma';
import { comparePassword, hashPassword } from '../lib/hashPassword';

const SUPER_ADMIN_EMAIL = process.env.SUPER_ADMIN_EMAIL;
const SUPER_ADMIN_PASSWORD = process.env.SUPER_ADMIN_PASSWORD;

export class Auth {
  async signin(c: Context) {
    const body = await c.req.json();
    const result = loginSchema.safeParse(body);

    if (!result.success) {
      return c.json({ err: 'Invalid input' }, 400);
    }

    const { email, password } = result.data;

    if (!SUPER_ADMIN_EMAIL || !SUPER_ADMIN_PASSWORD) {
      return c.json(
        { err: 'Super admin env credentials are not configured' },
        500,
      );
    }

    const isEnvCredentialMatch =
      email === SUPER_ADMIN_EMAIL && password === SUPER_ADMIN_PASSWORD;

    if (!isEnvCredentialMatch) {
      return c.json({ err: 'Invalid super admin credentials' }, 401);
    }

    const passwordHash = await hashPassword(SUPER_ADMIN_PASSWORD);

    const user = await prisma.user.upsert({
      where: { email: SUPER_ADMIN_EMAIL },
      create: {
        email: SUPER_ADMIN_EMAIL,
        passwordHash,
        role: 'SUPER_ADMIN',
      },
      update: {
        passwordHash,
        role: 'SUPER_ADMIN',
      },
    });

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

  async managerSignin(c: Context) {
    const body = await c.req.json();
    const result = managerLoginSchema.safeParse(body);

    if (!result.success) {
      return c.json({ err: 'Invalid input' }, 400);
    }

    const { username, password } = result.data;

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
