import { Hono } from 'hono';
import { proxyAuth, requireRole, ROLES } from '../proxy';
import { Driver } from '../controllers/driver.controller';

const driverRoute = new Hono();
const controller = new Driver();

const authRole = requireRole(ROLES.MANAGER);
const driverRole = requireRole(ROLES.DRIVER);

driverRoute.post(
  '/create-driver-profile',
  proxyAuth,
  authRole,
  controller.createDriver,
);
driverRoute.get('/get-drivers', proxyAuth, authRole, controller.getDrivers);
driverRoute.patch('/update-distance', proxyAuth, driverRole, controller.updateDistance);
driverRoute.patch('/:driverId', proxyAuth, authRole, controller.editDriver);
driverRoute.delete('/:driverId', proxyAuth, authRole, controller.deleteDriver);

export default driverRoute;
