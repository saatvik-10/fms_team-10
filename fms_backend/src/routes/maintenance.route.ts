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

export default maintenanceRoute;

