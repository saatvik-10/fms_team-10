import { Hono } from 'hono';
import { proxyAuth, requireRole, ROLES } from '../proxy';
import { Maintenance } from '../controllers/maintenance.controller';

const maintenanceRoute = new Hono();
const controller = new Maintenance();

// Dashboard Routes
maintenanceRoute.get('/dashboard', proxyAuth, requireRole(ROLES.MAINTENANCE), controller.getDashboard);

// Work Order Routes
maintenanceRoute.get('/work-orders', proxyAuth, requireRole(ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.listWorkOrders);
maintenanceRoute.get('/work-orders/:id', proxyAuth, requireRole(ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.getWorkOrder);
maintenanceRoute.post('/work-orders', proxyAuth, requireRole(ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.createWorkOrder);
maintenanceRoute.put('/work-orders/:id', proxyAuth, requireRole(ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.replaceWorkOrder);
maintenanceRoute.patch('/work-orders/:id', proxyAuth, requireRole(ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.updateWorkOrder);
maintenanceRoute.delete('/work-orders/:id', proxyAuth, requireRole(ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.deleteWorkOrder);

// Maintenance Scheduling Routes
maintenanceRoute.get('/schedules', proxyAuth, requireRole(ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.listSchedules);
maintenanceRoute.get('/schedules/:id', proxyAuth, requireRole(ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.getSchedule);
maintenanceRoute.post('/schedules', proxyAuth, requireRole(ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.createSchedule);
maintenanceRoute.put('/schedules/:id', proxyAuth, requireRole(ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.replaceSchedule);
maintenanceRoute.patch('/schedules/:id', proxyAuth, requireRole(ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.updateSchedule);
maintenanceRoute.delete('/schedules/:id', proxyAuth, requireRole(ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.deleteSchedule);

// Trip Inspection Routes
maintenanceRoute.get('/inspections', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.listInspections);
maintenanceRoute.get('/inspections/:id', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.getInspection);
maintenanceRoute.post('/inspections', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.createInspection);
maintenanceRoute.put('/inspections/:id', proxyAuth, requireRole(ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.replaceInspection);
maintenanceRoute.patch('/inspections/:id', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.updateInspection);
maintenanceRoute.delete('/inspections/:id', proxyAuth, requireRole(ROLES.MAINTENANCE, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.deleteInspection);

// Issue Routes
maintenanceRoute.get('/issues', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.listIssues);
maintenanceRoute.get('/issues/:id', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.getIssue);
maintenanceRoute.put('/issues/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.replaceIssue);
maintenanceRoute.patch('/issues/:id', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.updateIssue);

// Vehicle Routes
maintenanceRoute.get('/vehicles', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.listVehicles);
maintenanceRoute.get('/vehicles/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.getVehicle);
maintenanceRoute.patch('/vehicles/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.updateVehicle);

// Notification Routes
maintenanceRoute.get('/notifications', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.listNotifications);
maintenanceRoute.patch('/notifications/:id', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.updateNotification);

// Report Routes
maintenanceRoute.get('/reports', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.listReports);
maintenanceRoute.get('/reports/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.getReport);
maintenanceRoute.post('/reports', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.createReport);
maintenanceRoute.patch('/reports/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.updateReport);
maintenanceRoute.delete('/reports/:id', proxyAuth, requireRole(ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.deleteReport);

export default maintenanceRoute;
