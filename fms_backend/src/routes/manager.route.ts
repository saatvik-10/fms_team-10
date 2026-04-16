import { Hono } from 'hono';
import { proxyAuth, requireRole } from '../proxy';
import { Manager } from '../controllers/manager.controller.ts';

const managerRoute = new Hono();
const controller = new Manager();

managerRoute.post(
  '/create',
  proxyAuth,
  requireRole('SUPER_ADMIN'),
  controller.createManager,
);
// managerRoute.post('/getAll', requireRole('SUPER_ADMIN', controller.getManagers)

export default managerRoute;
