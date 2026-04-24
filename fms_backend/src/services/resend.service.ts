import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API);

type CredentialsMailInput = {
  userEmail: string;
  role: 'Manager' | 'Maintenance' | 'Driver' | string;
  username: string;
  password: string;
  senderRole?: 'Super Admin' | 'Manager' | string;
};

export async function sendCredentialsMail({
  userEmail,
  role,
  username,
  password,
  senderRole = 'Super Admin',
}: CredentialsMailInput) {
  if (!process.env.RESEND_API) {
    throw new Error('RESEND_API is not configured');
  }

  if (!process.env.CREDENTIALS_MAIL) {
    throw new Error('CREDENTIALS_MAIL is not configured');
  }

  const { data, error } = await resend.emails.send({
    from: process.env.CREDENTIALS_MAIL!,
    to: userEmail,
    subject: `Your ${role} login credentials`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #111827;">Welcome to the Fleet Management System</h2>
        <p>${senderRole} has created your <strong>${role}</strong> account and shared your login details below.</p>
        <div style="background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 8px; padding: 16px; margin: 20px 0;">
          <p style="margin: 0 0 8px;"><strong>Username:</strong> ${username}</p>
          <p style="margin: 0;"><strong>Password:</strong> ${password}</p>
        </div>
        <p>Please log in and change your password after the first login if your account policy requires it.</p>
        <p>If you did not expect this email, please contact your ${senderRole.toLowerCase()} administrator immediately.</p>
        <hr style="border: 1px solid #e5e7eb; margin: 20px 0;">
        <p style="color: #6b7280; font-size: 12px;">This is an automated account access email.</p>
      </div>
    `,
  });

  if (error) {
    throw error;
  }

  return data;
}

type VerificationOtpInput = {
  userEmail: string;
  otp: string;
};

export async function verificationOTP({ userEmail, otp }: VerificationOtpInput) {
  if (!process.env.RESEND_API) {
    throw new Error('RESEND_API is not configured');
  }

  if (!process.env.CREDENTIALS_MAIL) {
    throw new Error('CREDENTIALS_MAIL is not configured');
  }

  const { data, error } = await resend.emails.send({
    from: process.env.CREDENTIALS_MAIL!,
    to: userEmail,
    subject: 'Your 6-digit verification code',
    text: `Your verification code is ${otp}. It expires shortly.`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; background: #ffffff;">
        <h2 style="color: #111827; margin-bottom: 12px;">Email verification</h2>
        <p style="color: #374151; line-height: 1.6;">Use the 6-digit code below to verify your email address.</p>
        <div style="background: #f3f4f6; border: 1px solid #e5e7eb; border-radius: 12px; padding: 20px; margin: 24px 0; text-align: center;">
          <div style="font-size: 32px; font-weight: 700; letter-spacing: 8px; color: #111827;">${otp}</div>
        </div>
        <p style="color: #374151; line-height: 1.6;">This code is valid for a short time. If you did not request it, you can ignore this email.</p>
        <hr style="border: 1px solid #e5e7eb; margin: 24px 0;">
        <p style="color: #6b7280; font-size: 12px;">This is an automated verification email.</p>
      </div>
    `,
  });

  if (error) {
    throw error;
  }

  return data;
}