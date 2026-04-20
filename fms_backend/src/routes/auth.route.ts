import { Hono } from 'hono';
import { proxyAuth } from '../proxy';
import { Auth } from '../controllers/auth.controller.ts';
import { sendCredentialsMail } from '../services/resend';

const authRoute = new Hono();
const controller = new Auth();

authRoute.post('/super-admin/signin', controller.signin);
authRoute.post('/manager/signin', controller.managerSignin);
authRoute.post('/test-credentials-mail', async (c) => {
	try {
		const body = await c.req.json();

		const { userEmail, role, username, password, senderRole } = body ?? {};

		if (!userEmail || !role || !username || !password) {
			return c.json(
				{
					err: 'userEmail, role, username, and password are required',
				},
				400,
			);
		}

		const data = await sendCredentialsMail({
			userEmail,
			role,
			username,
			password,
			senderRole,
		});

		return c.json({
			message: 'Credentials email sent',
			data,
		});
	} catch (error) {
		console.error('Failed to send credentials email', error);
		return c.json(
			{
				err: 'Failed to send credentials email',
				details: error instanceof Error ? error.message : error,
			},
			500,
		);
	}
});
authRoute.get('/me', proxyAuth, controller.getMe);

export default authRoute;