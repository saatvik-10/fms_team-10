import { randomInt } from 'node:crypto';

type StoredOtp = {
  otp: string;
  expiresAt: number;
  sentAt: number;
};

const OTP_TTL_MS = 5 * 60 * 1000;
const OTP_SEND_COOLDOWN_MS = 60 * 1000;

export const otpStore = new Map<string, StoredOtp>();
export const otpVerifyAttempts = new Map<string, number>();

export const isCooldownActive = (storedOtp: StoredOtp, now: number) => {
  return now - storedOtp.sentAt < OTP_SEND_COOLDOWN_MS;
};

export const createOtpCode = () => randomInt(100000, 1000000).toString();

export const saveOtpForEmail = (email: string, otp: string, now: number) => {
  otpStore.set(email, {
    otp,
    expiresAt: now + OTP_TTL_MS,
    sentAt: now,
  });
  otpVerifyAttempts.set(email, 0);
};

export const getNextVerifyAttempt = (email: string) => {
  const nextAttempt = (otpVerifyAttempts.get(email) ?? 0) + 1;
  otpVerifyAttempts.set(email, nextAttempt);
  return nextAttempt;
};

export const clearOtpState = (email: string) => {
  otpStore.delete(email);
  otpVerifyAttempts.delete(email);
};
