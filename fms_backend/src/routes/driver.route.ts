import { Hono } from 'hono';
import { proxyAuth, requireRole, ROLES } from '../proxy';
import { Driver } from '../controllers/driver.controller';

const driverRoute = new Hono();
const controller = new Driver();

// Dashboard Routes
driverRoute.get('/dashboard', proxyAuth, requireRole(ROLES.DRIVER), controller.getDashboard);

// Basic Tracking Routes
driverRoute.get('/tracking', proxyAuth, requireRole(ROLES.DRIVER), controller.listTracking);
driverRoute.patch('/tracking/:id', proxyAuth, requireRole(ROLES.DRIVER), controller.updateTracking);

// Geofencing Routes
driverRoute.get('/geofences', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.listGeofences);
driverRoute.get('/geofences/:id', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.getGeofence);

// Issue Reporting Routes
driverRoute.get('/issues', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.listIssues);
driverRoute.post('/issues', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.createIssue);
driverRoute.patch('/issues/:id', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.updateIssue);

// Trip Lifecycle Routes
driverRoute.get('/trips', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.listTrips);
driverRoute.get('/trips/:id', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.getTrip);
driverRoute.patch('/trips/:id', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.updateTrip);

// Notification Routes
driverRoute.get('/notifications', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.listNotifications);
driverRoute.patch('/notifications/:id', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MANAGER, ROLES.SUPER_ADMIN, ROLES.MAINTENANCE), controller.updateNotification);

// Report Routes
driverRoute.get('/reports', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.listReports);
driverRoute.get('/reports/:id', proxyAuth, requireRole(ROLES.DRIVER, ROLES.MANAGER, ROLES.SUPER_ADMIN), controller.getReport);

export default driverRoute;
