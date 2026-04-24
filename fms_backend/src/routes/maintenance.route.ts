import { Hono } from 'hono';
import { proxyAuth, requireRole, ROLES } from '../proxy';
import { Maintenance } from '../controllers/maintenance.controller';

const maintenanceRoute = new Hono();
const controller = new Maintenance();

maintenanceRoute.post(
  '/create-maintenance-profile',
  proxyAuth,
  requireRole(ROLES.MANAGER),
  controller.createMaintenance,
);

maintenanceRoute.get(
  '/get-maintenances',
  proxyAuth,
  requireRole(ROLES.MANAGER),
  controller.getMaintenances,
);

maintenanceRoute.delete(
  '/:maintenanceId',
  proxyAuth,
  requireRole(ROLES.MANAGER),
  controller.deleteMaintenance,
);

export default maintenanceRoute;

