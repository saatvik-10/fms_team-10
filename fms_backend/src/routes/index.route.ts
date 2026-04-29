import { Hono } from 'hono';
import authRoute from './auth.route';
import managerRoute from './manager.route';
import driverRoute from './driver.route';
import maintenanceRoute from './maintenance.route';
import vehicleRoute from './vehicle.route';
import tripRoute from './trips.route';
import issueRoute from './issue.route';

const router = new Hono();

router.route('/auth', authRoute);
router.route('/manager', managerRoute);
router.route('/driver', driverRoute);
router.route('/maintenance', maintenanceRoute);
router.route('/vehicle', vehicleRoute);
router.route('/trip', tripRoute);
router.route('/issue', issueRoute);

export default router;