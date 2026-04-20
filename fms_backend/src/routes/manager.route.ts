import { Hono } from 'hono';
import { proxyAuth, requireRole, ROLES } from '../proxy';
import { Manager } from '../controllers/manager.controller.ts';

const managerRoute = new Hono();
const controller = new Manager();

// Manager Account Routes
managerRoute.post(
  '/create',
  proxyAuth,
  requireRole(ROLES.SUPER_ADMIN),
  controller.createManager,
);
managerRoute.get('/me', proxyAuth, requireRole(ROLES.MANAGER), controller.getMyProfile);

// Driver Routes
managerRoute.get('/drivers', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.listDrivers);
managerRoute.get('/drivers/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.getDriver);
managerRoute.post('/drivers', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.createDriver);
managerRoute.put('/drivers/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.replaceDriver);
managerRoute.patch('/drivers/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.updateDriver);
managerRoute.delete('/drivers/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.deleteDriver);

// Vehicle Routes
managerRoute.get('/vehicles', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.listVehicles);
managerRoute.get('/vehicles/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.getVehicle);
managerRoute.post('/vehicles', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.createVehicle);
managerRoute.put('/vehicles/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.replaceVehicle);
managerRoute.patch('/vehicles/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.updateVehicle);
managerRoute.delete('/vehicles/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.deleteVehicle);

// Assignment Routes
managerRoute.get('/assignments', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.listAssignments);
managerRoute.get('/assignments/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.getAssignment);
managerRoute.post('/assignments', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.createAssignment);
managerRoute.put('/assignments/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.replaceAssignment);
managerRoute.patch('/assignments/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.updateAssignment);
managerRoute.delete('/assignments/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.deleteAssignment);

// Trip Routes
managerRoute.get('/trips', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.listTrips);
managerRoute.get('/trips/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.getTrip);
managerRoute.post('/trips', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.createTrip);
managerRoute.put('/trips/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.replaceTrip);
managerRoute.patch('/trips/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.updateTrip);
managerRoute.delete('/trips/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.deleteTrip);

// Notification Routes
managerRoute.get('/notifications', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.DRIVER, ROLES.MAINTENANCE), controller.listNotifications);
managerRoute.post('/notifications', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.createNotification);
managerRoute.patch('/notifications/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.DRIVER, ROLES.MAINTENANCE), controller.updateNotification);
managerRoute.delete('/notifications/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.deleteNotification);

// Report Routes
managerRoute.get('/reports', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.listReports);
managerRoute.get('/reports/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.getReport);
managerRoute.post('/reports', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.createReport);
managerRoute.patch('/reports/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.updateReport);
managerRoute.delete('/reports/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.deleteReport);

// Super Admin And Role Management Routes
managerRoute.get('/roles', proxyAuth, requireRole(ROLES.SUPER_ADMIN), controller.listRoles);
managerRoute.patch('/roles/:id', proxyAuth, requireRole(ROLES.SUPER_ADMIN), controller.updateRole);

export default managerRoute;
