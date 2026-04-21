import type { Context } from 'hono';
import { sendCredentialsMail } from '../services/resend';
import { createDriverSchema } from '../validators/driver.validator';
import { nanoid } from 'nanoid';
import { prisma } from '../../prisma';
import { hashPassword } from '../lib/hashPassword';

export class Driver {
  async createDriver(c: Context) {
    const body = await c.req.json();
    const result = createDriverSchema.safeParse(body);

    if (!result.success) {
      return c.json(
        { err: 'Invalid input', details: result.error.flatten() },
        400,
      );
    }

    const { fullName, email, licenseNumber, expiryDate, classes, phone, address } = result.data;
    const managerId = c.get('userId') as string;

    const existingEmailUser = await prisma.user.findUnique({ where: { email } });
    if (existingEmailUser) {
      return c.json({ err: 'Email already in use' }, 409);
    }

    const existingDriver = await prisma.driver.findUnique({ where: { phone } });
    if (existingDriver) {
      return c.json({ err: 'Phone already in use' }, 409);
    }

    const firstName = fullName.split(' ')[0]!.toLowerCase();
    const username = `${firstName}_${nanoid(3)}`;
    const password = nanoid();
    const passwordHash = await hashPassword(password);

    const user = await prisma.user.create({
      data: {
        email,
        username,
        passwordHash,
        role: 'DRIVER',
        createdById: managerId,
        driver: {
          create: {
            name: fullName,
            email,
            phone,
            address,
            licenceNumber: licenseNumber,
            expiryDate,
            classes,
          },
        },
      },
      include: {
        driver: true,
      },
    });

    let mailStatus: { sent: boolean; details?: string } = { sent: true };

    try {
      await sendCredentialsMail({
        userEmail: email,
        role: 'Driver',
        username,
        password,
        senderRole: 'Manager',
      });
    } catch (error) {
      console.error('Failed to send driver credentials email', error);
      mailStatus = {
        sent: false,
        details: error instanceof Error ? error.message : 'Unknown mail error',
      };
    }

    return c.json(
      {
        message: 'Driver created successfully',
        credentials: {
          username,
          password,
        },
        mail: mailStatus,
        driver: {
          id: user.driver?.id,
          name: user.driver?.name,
          email: user.driver?.email,
          username: user.username,
          phone: user.driver?.phone,
          address: user.driver?.address,
          licenceNumber: user.driver?.licenceNumber,
          expiryDate: user.driver?.expiryDate,
          classes: user.driver?.classes,
          createdAt: user.driver?.createdAt,
        },
      },
      201,
    );
  }

  async getDrivers(c: Context) {
    const userId = c.get('userId') as string;

    const drivers = await prisma.driver.findMany({
      where: {
        user: {
          createdById: userId,
        },
      },
      include: {
        user: true,
      },
    });

    return c.json({
      drivers: drivers.map((driver) => ({
        id: driver.id,
        name: driver.name,
        email: driver.email,
        username: driver.user.username,
        phone: driver.phone,
        address: driver.address,
        licenceNumber: driver.licenceNumber,
        expiryDate: driver.expiryDate,
        classes: driver.classes,
        createdAt: driver.createdAt,
      })),
    });
  }
}
