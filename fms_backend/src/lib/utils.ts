import { R2Service } from '../services/r2.service';

export const calculateAge = (dob: Date): number => {
  const now = new Date();
  let age = now.getFullYear() - dob.getFullYear();
  const monthDiff = now.getMonth() - dob.getMonth();

  if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < dob.getDate())) {
    age -= 1;
  }

  return age;
};

export function decodeBase64Image(input: string) {
  const trimmed = input.trim();
  const base64 = trimmed.includes('base64,')
    ? trimmed.split('base64,').at(-1) ?? trimmed
    : trimmed;

  return Buffer.from(base64, 'base64');
}

export function extractKeyFromUrl(url: string | null | undefined) {
  if (!url) {
    return null;
  }

  try {
    const parsed = new URL(url);
    const parts = parsed.pathname.split('/').filter(Boolean);
    if (!parts.length) {
      return null;
    }

    return parts[0] === process.env.CLOUDFLARE_BUCKET_NAME
      ? parts.slice(1).join('/')
      : parts.join('/');
  } catch {
    return null;
  }
}

export async function deleteUploadedKeys(keys: Array<string | null | undefined>) {
  const r2 = new R2Service();
  const validKeys = keys.filter((key): key is string => Boolean(key));
  await Promise.allSettled(validKeys.map((key) => r2.deleteObject(key)));
}

export function getImageMeta(base64Image: string) {
  const matched = base64Image.match(/^data:(image\/[a-zA-Z0-9.+-]+);base64,/);
  const contentType = matched?.[1] ?? 'image/jpeg';

  if (contentType === 'image/png') {
    return { contentType, extension: 'png' };
  }

  if (contentType === 'image/webp') {
    return { contentType, extension: 'webp' };
  }

  return { contentType, extension: 'jpg' };
}

export function normalizeDriverExpiryDate(date: Date | string | null | undefined): string | null {
  if (!date) {
    return null;
  }

  const trimmed = typeof date === 'string' ? date.trim() : date.toISOString();

  const isoParsed = new Date(trimmed);
  if (!Number.isNaN(isoParsed.getTime())) {
    return isoParsed.toISOString();
  }

  const ddmmyyyy = /^(\d{2})-(\d{2})-(\d{4})$/;
  const ddmmyyyyMatch = trimmed.match(ddmmyyyy);
  if (ddmmyyyyMatch) {
    const [, day, month, year] = ddmmyyyyMatch;
    const converted = new Date(`${year}-${month}-${day}T00:00:00.000Z`);
    if (!Number.isNaN(converted.getTime())) {
      return converted.toISOString();
    }
  }

  const yyyymmdd = /^(\d{4})-(\d{2})-(\d{2})$/;
  const yyyymmddMatch = trimmed.match(yyyymmdd);
  if (yyyymmddMatch) {
    const [, year, month, day] = yyyymmddMatch;
    const converted = new Date(`${year}-${month}-${day}T00:00:00.000Z`);
    if (!Number.isNaN(converted.getTime())) {
      return converted.toISOString();
    }
  }

  return null;
}