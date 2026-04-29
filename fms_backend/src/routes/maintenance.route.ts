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

maintenanceRoute.get(
  '/work-orders/vehicles',
  proxyAuth,
  requireRole(ROLES.MAINTENANCE),
  controller.getWorkOrderVehicles,
);

maintenanceRoute.post(
  '/work-orders',
  proxyAuth,
  requireRole(ROLES.MAINTENANCE),
  controller.createWorkOrder,
);

maintenanceRoute.get(
  '/work-orders',
  proxyAuth,
  requireRole(ROLES.MAINTENANCE),
  controller.getWorkOrders,
);

maintenanceRoute.patch(
  '/work-orders/:id/complete',
  proxyAuth,
  requireRole(ROLES.MAINTENANCE),
  controller.completeWorkOrder,
);

maintenanceRoute.patch(
  '/update-maintenance/:maintenanceId',
  proxyAuth,
  requireRole(ROLES.MANAGER),
  controller.updateMaintenance,
);

maintenanceRoute.delete(
  '/:maintenanceId',
  proxyAuth,
  requireRole(ROLES.MANAGER),
  controller.deleteMaintenance,
);

maintenanceRoute.get(
  '/inspections',
  proxyAuth,
  requireRole(ROLES.MAINTENANCE),
  controller.getInspections,
);

maintenanceRoute.patch(
  '/inspections/:id',
  proxyAuth,
  requireRole(ROLES.MAINTENANCE),
  controller.updateInspection,
);

export default maintenanceRoute;
