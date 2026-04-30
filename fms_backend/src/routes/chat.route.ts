import { Hono } from 'hono';
import { proxyAuth } from '../proxy';
import { ChatController } from '../controllers/chat.controller';

const chatRoute = new Hono();
const controller = new ChatController();

chatRoute.get('/rooms', proxyAuth, controller.getRooms);
chatRoute.post('/rooms', proxyAuth, controller.createRoom);
chatRoute.get('/rooms/:roomId/messages', proxyAuth, controller.getMessages);
chatRoute.post('/rooms/:roomId/messages', proxyAuth, controller.sendMessage);
chatRoute.put('/rooms/:roomId/read', proxyAuth, controller.markRead);
chatRoute.get('/users', proxyAuth, controller.getUsers);

export default chatRoute;
