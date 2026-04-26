import { Hono } from 'hono';
import { proxyAuth, requireRole, ROLES } from '../proxy';
import { Vehicle } from '../controllers/vehicle.controller';

const vehicleRoute = new Hono();
const controller = new Vehicle();

const authRole = requireRole(ROLES.MANAGER);

vehicleRoute.post('/create-vehicle-profile', proxyAuth, authRole, controller.createVehicle);
vehicleRoute.get('/get-vehicles', proxyAuth, authRole, controller.getVehicles);
vehicleRoute.get('/:vehicleId', proxyAuth, authRole, controller.getVehicleById);
vehicleRoute.patch('/:vehicleId', proxyAuth, authRole, controller.updateVehicle);
vehicleRoute.delete('/:vehicleId', proxyAuth, authRole, controller.deleteVehicle);

vehicleRoute.patch('/:vehicleId/current-trip', proxyAuth, authRole, controller.updateCurrentTrip);
vehicleRoute.patch('/:vehicleId/maintenance', proxyAuth, authRole, controller.updateMaintenance);
vehicleRoute.post('/:vehicleId/history', proxyAuth, authRole, controller.addTripHistory);
vehicleRoute.get('/:vehicleId/history', proxyAuth, authRole, controller.getTripHistory);

export default vehicleRoute;