import type { Context } from 'hono';
import { sendCredentialsMail } from '../services/resend.service';
import {
  createDriverSchema,
  updateDriverSchema,
} from '../validators/driver.validator';
import { nanoid } from 'nanoid';
import { prisma } from '../../prisma';
import { hashPassword } from '../lib/hashPassword';
import { genPswd } from '../lib/genPswd';
import { R2Service } from '../services/r2.service';
import { decodeBase64Image, extractKeyFromUrl, deleteUploadedKeys } from '../lib/utils';

const r2Service = new R2Service();

function buildDriverTitle(classes: string[]) {
  return `${classes[0] ?? 'LMV-NT'} Certified Driver`;
}

async function uploadDriverLicenseImage(params: {
  managerId: string;
  firstName: string;
  side: 'front' | 'back';
  imageData: string;
}) {
  const upload = await r2Service.uploadByScope({
    scope: {
      role: 'manager',
      userId: params.managerId,
      documentType: 'dl',
    },
    fileName: `${params.firstName}_dl_${params.side}_${nanoid(4)}.jpg`,
    body: decodeBase64Image(params.imageData),
    contentType: 'image/jpeg',
  });

  const url = await r2Service.getSignedDownloadUrl(upload.key);

  return {
    key: upload.key,
    url,
  };
}

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

    const {
      fullName,
      email,
      licenseNumber,
      expiryDate,
      classes,
      phone,
      address,
      licenseFrontImage,
      licenseBackImage,
    } = result.data;
    const managerId = c.get('userId') as string;

    const existingEmailUser = await prisma.user.findUnique({
      where: { email },
      select: { id: true },
    });
    if (existingEmailUser) {
      return c.json({ err: 'Email already in use' }, 409);
    }

    const existingDriver = await prisma.driver.findUnique({ where: { phone } });
    if (existingDriver) {
      return c.json({ err: 'Phone already in use' }, 409);
    }

    const firstName = fullName.split(' ')[0]!.toLowerCase();
    const username = `${firstName}_${nanoid(3)}`;
    const password = genPswd();
    const passwordHash = await hashPassword(password);
    const [frontImage, backImage] = await Promise.all([
      uploadDriverLicenseImage({
        managerId,
        firstName,
        side: 'front',
        imageData: licenseFrontImage,
      }),
      uploadDriverLicenseImage({
        managerId,
        firstName,
        side: 'back',
        imageData: licenseBackImage,
      }),
    ]);

    try {
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
              status: 'ACTIVE',
              licenceNumber: licenseNumber,
              expiryDate,
              classes,
              dlFrontImageUrl: frontImage.url,
              dlBackImageUrl: backImage.url,
            },
          },
        },
        select: {
          username: true,
          driver: {
            select: {
              id: true,
              name: true,
              email: true,
              phone: true,
              address: true,
              licenceNumber: true,
              expiryDate: true,
              classes: true,
              dlFrontImageUrl: true,
              dlBackImageUrl: true,
              createdAt: true,
            },
          },
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
            dlFrontImageUrl: user.driver?.dlFrontImageUrl,
            dlBackImageUrl: user.driver?.dlBackImageUrl,
            createdAt: user.driver?.createdAt,
          },
        },
        201,
      )
    } catch (error) {
      await deleteUploadedKeys([frontImage.key, backImage.key]);
      throw error;
    }
  }

  async getDrivers(c: Context) {
    const userId = c.get('userId') as string;

    const drivers = await prisma.driver.findMany({
      where: {
        user: {
          createdById: userId,
        },
      },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        address: true,
        licenceNumber: true,
        expiryDate: true,
        classes: true,
        dlFrontImageUrl: true,
        dlBackImageUrl: true,
        createdAt: true,
        status: true,
        user: {
          select: {
            username: true,
          },
        },
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
        dlFrontImageUrl: driver.dlFrontImageUrl,
        dlBackImageUrl: driver.dlBackImageUrl,
        createdAt: driver.createdAt,
        status: driver.status,
      })),
    });
  }

  async editDriver(c: Context) {
    const driverId = c.req.param('driverId');
    const body = await c.req.json();
    const result = updateDriverSchema.safeParse(body);

    if (!result.success) {
      return c.json(
        { err: 'Invalid input', details: result.error.flatten() },
        400,
      );
    }

    const managerId = c.get('userId') as string;
    const existingDriver = await prisma.driver.findFirst({
      where: {
        id: driverId,
        user: {
          createdById: managerId,
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

    if (!existingDriver) {
      return c.json({ err: 'Driver not found' }, 404);
    }

    const nextEmail = result.data.email ?? existingDriver.email;
    const nextPhone = result.data.phone ?? existingDriver.phone;

    if (result.data.email && result.data.email !== existingDriver.email) {
      const emailOwner = await prisma.user.findFirst({
        where: {
          email: result.data.email,
          id: { not: existingDriver.userId },
        },
        select: { id: true },
      });

      if (emailOwner) {
        return c.json({ err: 'Email already in use' }, 409);
      }
    }

    if (result.data.phone && result.data.phone !== existingDriver.phone) {
      const phoneOwner = await prisma.driver.findFirst({
        where: {
          phone: result.data.phone,
          id: { not: existingDriver.id },
        },
        select: { id: true },
      });

      if (phoneOwner) {
        return c.json({ err: 'Phone already in use' }, 409);
      }
    }

    try {
      const updatedDriver = await prisma.$transaction(async (tx) => {
        await tx.user.update({
          where: { id: existingDriver.userId },
          data: {
            ...(result.data.email ? { email: result.data.email } : {}),
          },
        });

        return tx.driver.update({
          where: { id: existingDriver.id },
          data: {
            ...(result.data.fullName ? { name: result.data.fullName } : {}),
            ...(result.data.email ? { email: result.data.email } : {}),
            ...(result.data.phone ? { phone: result.data.phone } : {}),
            ...(result.data.address !== undefined ? { address: result.data.address } : {}),
            ...(result.data.licenseNumber
              ? { licenceNumber: result.data.licenseNumber }
              : {}),
            ...(result.data.expiryDate ? { expiryDate: result.data.expiryDate } : {}),
            ...(result.data.classes ? { classes: result.data.classes } : {}),
          },
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            address: true,
            licenceNumber: true,
            expiryDate: true,
            classes: true,
            dlFrontImageUrl: true,
            dlBackImageUrl: true,
            createdAt: true,
            user: {
              select: { username: true },
            },
          },
        });
      });

      return c.json({
        message: 'Driver updated successfully',
        driver: {
          id: updatedDriver.id,
          name: updatedDriver.name,
          email: updatedDriver.email,
          username: updatedDriver.user.username,
          phone: updatedDriver.phone,
          address: updatedDriver.address,
          licenceNumber: updatedDriver.licenceNumber,
          expiryDate: updatedDriver.expiryDate,
          classes: updatedDriver.classes,
          dlFrontImageUrl: updatedDriver.dlFrontImageUrl,
          dlBackImageUrl: updatedDriver.dlBackImageUrl,
          createdAt: updatedDriver.createdAt,
        },
      });
    } catch (error) {
      throw error;
    }
  }

  async deleteDriver(c: Context) {
    const driverId = c.req.param('driverId');
    const managerId = c.get('userId') as string;

    const driver = await prisma.driver.findFirst({
      where: {
        id: driverId,
        user: {
          createdById: managerId,
        },
      },
      select: {
        id: true,
        userId: true,
        dlFrontImageUrl: true,
        dlBackImageUrl: true,
      },
    });

    if (!driver) {
      return c.json({ err: 'Driver not found' }, 404);
    }

    await prisma.$transaction([
      prisma.driver.delete({
        where: { id: driver.id },
      }),
      prisma.user.delete({
        where: { id: driver.userId },
      }),
    ]);

    await deleteUploadedKeys([
      extractKeyFromUrl(driver.dlFrontImageUrl),
      extractKeyFromUrl(driver.dlBackImageUrl),
    ]);

    return c.json({ message: 'Driver deleted successfully' });
  }
}
