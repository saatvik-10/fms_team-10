import type { Context } from 'hono';
import {
  superAdminLoginSchema,
  loginSchema,
  otpMailSchema,
  verifyOtpSchema,
} from '../validators/auth.validator';
import { jwtAuth } from '../lib/jwt';
import { prisma } from '../../prisma';
import { comparePassword, hashPassword } from '../lib/hashPassword';
import { verificationOTP } from '../services/resend.service';
import {
  otpStore,
  isCooldownActive,
  createOtpCode,
  saveOtpForEmail,
  getNextVerifyAttempt,
  clearOtpState,
} from '../lib/otp';

const SUPER_ADMIN_EMAIL = process.env.SUPER_ADMIN_EMAIL;
const SUPER_ADMIN_PASSWORD = process.env.SUPER_ADMIN_PASSWORD;
const MAX_VERIFY_ATTEMPTS = 10;

export class Auth {
  async signin(c: Context) {
    const body = await c.req.json();
    const result = superAdminLoginSchema.safeParse(body);

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
      select: {
        id: true,
        role: true,
      },
    });

    const token = await jwtAuth({
      userId: user.id,
      role: user.role,
    });

    return c.json({ token });
  }

  async userSignin(c: Context) {
    const body = await c.req.json();
    const result = loginSchema.safeParse(body);

    if (!result.success) {
      return c.json({ err: 'Invalid input' }, 400);
    }

    const { username, password } = result.data;

    const user = await prisma.user.findUnique({
      where: { username },
      select: {
        id: true,
        email: true,
        username: true,
        passwordHash: true,
        role: true,
        manager: {
          select: {
            name: true,
            phone: true,
            address: true,
          },
        },
        driver: {
          select: {
            name: true,
            phone: true,
            address: true,
            licenceNumber: true,
            expiryDate: true,
            classes: true,
          },
        },
        maintenance: {
          select: {
            name: true,
            phone: true,
            email: true,
            dob: true,
          },
        },
      },
    });

    if (!user) {
      return c.json({ err: 'Invalid credentials' }, 401);
    }

    const isPasswordValid = await comparePassword(password, user.passwordHash!);
    if (!isPasswordValid) {
      return c.json({ err: 'Invalid credentials' }, 401);
    }

    // Prevent SUPER_ADMIN from using this endpoint
    if (user.role === 'SUPER_ADMIN') {
      return c.json({ err: 'Invalid credentials' }, 401);
    }

    const token = await jwtAuth({
      userId: user.id,
      role: user.role,
    });

    // Return role-specific profile based on role
    let profileData: Record<string, any> = { id: user.id, email: user.email };

    if (user.role === 'MANAGER' && user.manager) {
      profileData = {
        ...profileData,
        name: user.manager.name,
        phone: user.manager.phone,
        address: user.manager.address,
      };
    } else if (user.role === 'DRIVER' && user.driver) {
      profileData = {
        ...profileData,
        name: user.driver.name,
        phone: user.driver.phone,
        address: user.driver.address,
        licenceNumber: user.driver.licenceNumber,
        expiryDate: user.driver.expiryDate,
        classes: user.driver.classes,
      };
    } else if (user.role === 'MAINTENANCE' && user.maintenance) {
      profileData = {
        ...profileData,
        name: user.maintenance.name,
        phone: user.maintenance.phone,
        email: user.maintenance.email,
        dob: user.maintenance.dob,
      };
    } else {
      return c.json({ err: 'Invalid credentials' }, 401);
    }

    return c.json({
      token,
      user: {
        ...profileData,
        role: user.role,
        username: user.username,
      },
    });
  }

  async sendOtpMail(c: Context) {
    const body = await c.req.json();
    const result = otpMailSchema.safeParse(body);

    if (!result.success) {
      return c.json({ err: 'Invalid input' }, 400);
    }

    const { email } = result.data;
    const existingOtp = otpStore.get(email);
    const now = Date.now();

    if (existingOtp && isCooldownActive(existingOtp, now)) {
      return c.json({ err: 'Please wait before requesting another OTP' }, 429);
    }

    const otp = createOtpCode();
    saveOtpForEmail(email, otp, now);

    await verificationOTP({
      userEmail: email,
      otp,
    });

    return c.json({
      message: 'Verification code sent successfully',
    });
  }

  async verifyOtp(c: Context) {
    const body = await c.req.json();
    const result = verifyOtpSchema.safeParse(body);

    if (!result.success) {
      return c.json({ err: 'Invalid input' }, 400);
    }

    const { email, otp } = result.data;
    const storedOtp = otpStore.get(email);
    const attempts = getNextVerifyAttempt(email);

    if (attempts > MAX_VERIFY_ATTEMPTS) {
      return c.json({ message: 'Too many requests' }, 429);
    }

    if (!storedOtp) {
      return c.json('Failure');
    }

    if (Date.now() > storedOtp.expiresAt) {
      clearOtpState(email);
      return c.json({ message: 'OTP expired' }, 410);
    }

    if (storedOtp.otp === otp) {
      clearOtpState(email);
      return c.json('Success');
    }

    return c.json('Failure');
  }

  async getProfile(c: Context) {
    const userId = c.get('userId') as string;
    const role = c.get('role') as string;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        username: true,
        role: true,
        createdAt: true,
        updatedAt: true,
        manager: {
          select: {
            name: true,
            phone: true,
            address: true,
          },
        },
        driver: {
          select: {
            name: true,
            phone: true,
            address: true,
            licenceNumber: true,
            expiryDate: true,
            classes: true,
          },
        },
        maintenance: {
          select: {
            name: true,
            phone: true,
            email: true,
            dob: true,
          },
        },
      },
    });

    if (!user) {
      return c.json({ err: 'User not found' }, 404);
    }

    let profileData: Record<string, any> = { id: user.id, email: user.email };

    if (role === 'MANAGER' && user.manager) {
      profileData = {
        ...profileData,
        name: user.manager.name,
        phone: user.manager.phone,
        address: user.manager.address,
      };
    } else if (role === 'DRIVER' && user.driver) {
      profileData = {
        ...profileData,
        name: user.driver.name,
        phone: user.driver.phone,
        address: user.driver.address,
        licenceNumber: user.driver.licenceNumber,
        expiryDate: user.driver.expiryDate,
        classes: user.driver.classes,
      };
    } else if (role === 'MAINTENANCE' && user.maintenance) {
      profileData = {
        ...profileData,
        name: user.maintenance.name,
        phone: user.maintenance.phone,
        email: user.maintenance.email,
        dob: user.maintenance.dob,
      };
    } else {
      return c.json({ err: 'Invalid user' }, 400);
    }

    return c.json({
      profile: {
        ...profileData,
        role: user.role,
        username: user.username,
        createdAt: user.createdAt,
      },
    });
  }
}
