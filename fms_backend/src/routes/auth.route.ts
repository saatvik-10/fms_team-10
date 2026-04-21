import { Hono } from 'hono';
import { proxyAuth } from '../proxy';
import { Auth } from '../controllers/auth.controller.ts';

const authRoute = new Hono();
const controller = new Auth();

authRoute.post('/super-admin/signin', controller.signin);
authRoute.post('/signin', controller.userSignin);
authRoute.post('/otp/send', controller.sendOtpMail);
authRoute.post('/verify-otp', controller.verifyOtp);
authRoute.get('/profile', proxyAuth, controller.getProfile);

export default authRoute;