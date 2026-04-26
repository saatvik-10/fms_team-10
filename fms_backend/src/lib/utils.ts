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