import { Hono } from 'hono';
import { proxyAuth, requireRole } from '../proxy';
import { Auth } from '../controllers/auth.controller.ts';

const authRoute = new Hono();
const controller = new Auth();

authRoute.post('/super-admin/login', controller.login);
authRoute.post('/manager', proxyAuth, requireRole('SUPER_ADMIN'), controller.createManager);
authRoute.get('/me', proxyAuth, controller.getMe);

export default authRoute;