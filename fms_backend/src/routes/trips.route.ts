import { Hono } from 'hono';
import { proxyAuth, ROLES, requireRole } from '../proxy';
import { Trip } from '../controllers/trips.controller';

const tripRoute = new Hono();
const controller = new Trip();

const authRole = requireRole(ROLES.MANAGER);
const driverRole = requireRole(ROLES.DRIVER)

tripRoute.post('/create-trip', proxyAuth, authRole, controller.createTrip)
tripRoute.get('/get-trip', proxyAuth, authRole, driverRole, controller.getTrip)
tripRoute.get('/get-trips', proxyAuth, authRole, controller.getTrips)

export default tripRoute;