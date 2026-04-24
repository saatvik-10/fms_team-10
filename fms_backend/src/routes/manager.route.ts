import { Hono } from 'hono';
import { proxyAuth, requireRole, ROLES } from '../proxy';
import { Manager } from '../controllers/manager.controller.ts';

const managerRoute = new Hono();
const controller = new Manager();

const authRole = requireRole(ROLES.MANAGER);

managerRoute.post(
  '/create-manager-profile',
  proxyAuth,
  requireRole(ROLES.SUPER_ADMIN),
  controller.createManager,
);
managerRoute.get('/:id', proxyAuth, requireRole(ROLES.SUPER_ADMIN), controller.getManager);

export default managerRoute;

