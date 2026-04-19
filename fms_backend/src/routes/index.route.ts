import { Hono } from 'hono';
import authRoute from './auth.route';
import managerRoute from './manager.route';

const router = new Hono();

router.route('/auth', authRoute);
router.route('/manager', managerRoute)

export default router;