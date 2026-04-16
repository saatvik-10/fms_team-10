import { Hono } from 'hono';
import { proxyAuth } from '../proxy';
import { Auth } from '../controllers/auth.controller.ts';

const authRoute = new Hono();
const controller = new Auth();

authRoute.post('/super-admin/signin', controller.signin);
authRoute.post('/manager/signin', controller.managerSignin);
authRoute.get('/me', proxyAuth, controller.getMe);

export default authRoute;