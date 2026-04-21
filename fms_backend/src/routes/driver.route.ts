import { Hono } from 'hono';
import { proxyAuth, requireRole, ROLES } from '../proxy';
import { Driver } from '../controllers/driver.controller';

const driverRoute = new Hono();
const controller = new Driver();

const authRole = requireRole(ROLES.MANAGER);

driverRoute.post(
  '/create-driver-profile',
  proxyAuth,
  authRole,
  controller.createDriver,
);
driverRoute.get('/get-drivers', proxyAuth, authRole, controller.getDrivers);

export default driverRoute;
