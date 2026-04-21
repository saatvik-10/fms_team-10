import { Hono } from 'hono';
import { proxyAuth } from '../proxy';
import { Auth } from '../controllers/auth.controller.ts';
import { sendCredentialsMail } from '../services/resend';

const authRoute = new Hono();
const controller = new Auth();

authRoute.post('/super-admin/signin', controller.signin);
authRoute.post('/signin', controller.userSignin);
authRoute.get('/profile', proxyAuth, controller.getProfile);

export default authRoute;