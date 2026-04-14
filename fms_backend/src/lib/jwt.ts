import { sign, verify } from 'hono/jwt';

interface JwtAuthProps {
  userId: string;
  role: string;
}

interface JwtVerifyResult {
  userId: string;
  role: string;
}

export const jwtAuth = async ({ userId, role }: JwtAuthProps) => {
  const payload = {
    userId,
    role,
    exp: Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60,
  };

  const token = await sign(payload, process.env.JWT_SECRET!, 'HS256');

  return token;
};

export const jwtVerify = async (token: string): Promise<JwtVerifyResult> => {
  try {
    const payload = await verify(token, process.env.JWT_SECRET!, 'HS256');
    return { userId: payload.userId as string, role: payload.role as string };
  } catch {
    throw new Error('Invalid Token');
  }
};
