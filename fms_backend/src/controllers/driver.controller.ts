import type { Context } from 'hono';

const notImplemented = (resource: string, action: string, id?: string) => {
  return { resource, action, ...(id ? { id } : {}) };
};

export class Driver {
  async getDashboard(c: Context) {
    return c.json(notImplemented('driver-dashboard', 'get'), 501);
  }

  async listTracking(c: Context) {
    return c.json(notImplemented('driver-tracking', 'list'), 501);
  }

  async updateTracking(c: Context) {
    return c.json(notImplemented('driver-tracking', 'update', c.req.param('id')), 501);
  }

  async listGeofences(c: Context) {
    return c.json(notImplemented('geofences', 'list'), 501);
  }

  async getGeofence(c: Context) {
    return c.json(notImplemented('geofences', 'get', c.req.param('id')), 501);
  }

  async listIssues(c: Context) {
    return c.json(notImplemented('issues', 'list'), 501);
  }

  async createIssue(c: Context) {
    return c.json(notImplemented('issues', 'create'), 501);
  }

  async updateIssue(c: Context) {
    return c.json(notImplemented('issues', 'update', c.req.param('id')), 501);
  }

  async listTrips(c: Context) {
    return c.json(notImplemented('trips', 'list'), 501);
  }

  async getTrip(c: Context) {
    return c.json(notImplemented('trips', 'get', c.req.param('id')), 501);
  }

  async updateTrip(c: Context) {
    return c.json(notImplemented('trips', 'update', c.req.param('id')), 501);
  }

  async listNotifications(c: Context) {
    return c.json(notImplemented('notifications', 'list'), 501);
  }

  async updateNotification(c: Context) {
    return c.json(notImplemented('notifications', 'update', c.req.param('id')), 501);
  }

  async listReports(c: Context) {
    return c.json(notImplemented('reports', 'list'), 501);
  }

  async getReport(c: Context) {
    return c.json(notImplemented('reports', 'get', c.req.param('id')), 501);
  }
}
