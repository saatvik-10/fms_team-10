import type { Context, Next } from 'hono';
import { jwtVerify } from './lib/jwt';

export const proxyAuth = async (ctx: Context, next: Next) => {
  const authHeader = ctx.req.header('Authorization');
  const token = authHeader?.startsWith('Bearer ')
    ? authHeader.slice(7).trim()
    : undefined;

  if (!token) {
    return ctx.text('Not Authenticated', 401);
  }

  try {
    const verified = await jwtVerify(token);
    ctx.set('userId', verified.userId);
    ctx.set('role', verified.role);
    await next();
  } catch {
    return ctx.json('Invalid Token', 403);
  }
};

export const requireRole = (...allowedRoles: string[]) => {
  return async (ctx: Context, next: Next) => {
    const role = ctx.get('role') as string;

    if (!role || !allowedRoles.includes(role)) {
      return ctx.json(`Access denied. Required role: ${allowedRoles}`, 401);
    }

    await next();
  };
};
