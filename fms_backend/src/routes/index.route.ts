import { Hono } from 'hono';
import authRoute from './auth.route';
import managerRoute from './manager.route';
import driverRoute from './driver.route';
import maintenanceRoute from './maintenance.route';

const router = new Hono();

router.route('/auth', authRoute);
router.route('/manager', managerRoute);
router.route('/driver', driverRoute);
router.route('/maintenance', maintenanceRoute);

export default router;