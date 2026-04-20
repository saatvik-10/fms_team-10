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
