import { Hono } from 'hono';
import { proxyAuth, requireRole, ROLES } from '../proxy';
import { IssueController } from '../controllers/issue.controller';

const issueRoute = new Hono();
const controller = new IssueController();

const driverRole = requireRole(ROLES.DRIVER);

issueRoute.post('/report', proxyAuth, driverRole, controller.createIssueReport);
issueRoute.get('/my-reports', proxyAuth, driverRole, controller.getIssueReports);
issueRoute.get('/my-reports/:issueId', proxyAuth, driverRole, controller.getIssueReportById);

export default issueRoute;
