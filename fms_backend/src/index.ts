import { Hono } from 'hono';
import { logger } from 'hono/logger';
import { cors } from 'hono/cors';
import { serve } from '@hono/node-server';

const port = process.env.PORT;

const app = new Hono();

app.use(logger());
app.use(cors());

app.get('/health', (c) => {
  return c.json({ status: 'ok' });
});

app.notFound((c) => {
  return c.json({ err: 'Page not found' }, 404);
});

serve({
  fetch: app.fetch,
  port: Number(port),
});

console.log(`Server running on port ${port}`);
