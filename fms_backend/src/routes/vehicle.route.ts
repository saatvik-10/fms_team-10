import { Hono } from 'hono';
import { proxyAuth, requireRole, ROLES } from '../proxy';
import { Vehicle } from '../controllers/vehicle.controller';

const vehicleRoute = new Hono();
const controller = new Vehicle();

const authRole = requireRole(ROLES.MANAGER)

vehicleRoute.post(
  '/create-vehicle-profile',
  proxyAuth,
  authRole,
  controller.createVehicle,
);

export default vehicleRoute;
