import type { Context } from 'hono';
import { prisma } from '../../prisma';
import {
  createRoomSchema,
  sendMessageSchema,
} from '../validators/chat.validator';
import { triggerRoomEvent, triggerUserEvent } from '../services/pusher.service';

async function resolveUserName(userId: string): Promise<string> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      role: true,
      manager: { select: { name: true } },
      driver: { select: { name: true } },
      maintenance: { select: { name: true } },
    },
  });

  if (!user) return 'Unknown';
  if (user.role === 'MANAGER' && user.manager) return user.manager.name;
  if (user.role === 'DRIVER' && user.driver) return user.driver.name;
  if (user.role === 'MAINTENANCE' && user.maintenance)
    return user.maintenance.name;
  if (user.role === 'SUPER_ADMIN') return 'Admin';
  return 'Unknown';
}

async function resolveUserRole(userId: string): Promise<string> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { role: true },
  });
  return user?.role?.toLowerCase() ?? 'unknown';
}

function formatMessage(msg: {
  id: string;
  roomId: string;
  senderId: string;
  senderName: string;
  senderRole: string;
  content: string;
  timestamp: Date;
  status: string;
  isStarred: boolean;
  attachmentType: string | null;
  attachmentUrl: string | null;
}) {
  return {
    id: msg.id,
    room_id: msg.roomId,
    sender_id: msg.senderId,
    sender_name: msg.senderName,
    sender_role: msg.senderRole,
    content: msg.content,
    timestamp: msg.timestamp.toISOString(),
    status: msg.status,
    is_starred: msg.isStarred,
    attachment_type: msg.attachmentType,
    attachment_url: msg.attachmentUrl,
  };
}

function formatRoom(
  room: {
    id: string;
    name: string;
    avatarInitials: string | null;
    roomType: string;
    participants: string[];
    participantNames: unknown;
    lastActivity: Date;
  },
  lastMessage: ReturnType<typeof formatMessage> | null,
  unreadCount: number,
) {
  return {
    id: room.id,
    name: room.name,
    avatar_initials: room.avatarInitials,
    room_type: room.roomType.toLowerCase(),
    participants: room.participants,
    participant_names: room.participantNames ?? {},
    last_message: lastMessage,
    unread_count: unreadCount,
    last_activity: room.lastActivity.toISOString(),
  };
}

export class ChatController {
  /**
   * GET /chat/rooms
   */
  async getRooms(c: Context) {
    const userId = c.get('userId') as string;

    const rooms = await prisma.chatRoom.findMany({
      where: { participants: { has: userId } },
      orderBy: { lastActivity: 'desc' },
      include: {
        messages: {
          orderBy: { timestamp: 'desc' },
          take: 1,
        },
        reads: {
          where: { userId },
        },
      },
    });

    const result = rooms.map((room) => {
      const lastMsg = room.messages[0] ?? null;
      const readCursor = room.reads[0]?.lastReadAt ?? new Date(0);

      let unreadCount = 0;
      if (
        lastMsg &&
        lastMsg.timestamp > readCursor &&
        lastMsg.senderId !== userId
      ) {
        unreadCount = 1;
      }

      return formatRoom(
        room,
        lastMsg ? formatMessage(lastMsg) : null,
        unreadCount,
      );
    });

    return c.json(result);
  }

  /**
   * POST /chat/rooms
   */
  async createRoom(c: Context) {
    const userId = c.get('userId') as string;
    const body = await c.req.json();
    const parsed = createRoomSchema.safeParse(body);

    if (!parsed.success) {
      return c.json(
        { err: 'Invalid input', details: parsed.error.flatten() },
        400,
      );
    }

    const { targetId, senderName, senderRole, message } = parsed.data;
    const senderId = userId;

    const targetExists = await prisma.user.findUnique({
      where: { id: targetId },
      select: { id: true },
    });

    if (!targetExists) {
      return c.json({ err: 'Target user not found' }, 404);
    }

    const targetName = await resolveUserName(targetId);

    const participantNames: Record<string, string> = {
      [senderId]: senderName,
      [targetId]: targetName,
    };

    const room = await prisma.chatRoom.create({
      data: {
        name: `${senderName} & ${targetName}`,
        roomType: 'DIRECT',
        participants: [senderId, targetId],
        participantNames,
        avatarInitials: targetName.charAt(0).toUpperCase(),
        lastActivity: new Date(),
        messages: {
          create: {
            senderId,
            senderName,
            senderRole,
            content: message,
            status: 'sent',
          },
        },
      },
      include: {
        messages: {
          orderBy: { timestamp: 'desc' },
          take: 1,
        },
      },
    });

    const lastMsg = room.messages[0]!;
    const formattedMsg = formatMessage(lastMsg);
    const formattedRoom = formatRoom(room, formattedMsg, 0);

    try {
      await triggerRoomEvent(
        room.id,
        'new-message',
        formattedMsg as unknown as Record<string, unknown>,
      );
      await triggerUserEvent(
        senderId,
        'new-message',
        formattedMsg as unknown as Record<string, unknown>,
      );
      await triggerUserEvent(
        targetId,
        'new-message',
        formattedMsg as unknown as Record<string, unknown>,
      );
    } catch (err) {
      console.error('Pusher trigger failed (createRoom):', err);
    }

    return c.json(formattedRoom, 201);
  }

  /**
   * GET /chat/rooms/:roomId/messages
   */
  async getMessages(c: Context) {
    const userId = c.get('userId') as string;
    const rawRoomId = c.req.param('roomId');

    if (!rawRoomId) {
      return c.json({ err: 'Room ID is required' }, 400);
    }

    // ✅ Normalize to lowercase to match Prisma's stored UUID format
    const roomId = rawRoomId.toLowerCase();

    const room = await prisma.chatRoom.findUnique({
      where: { id: roomId },
    });

    if (!room) {
      return c.json(
        { err: 'Room not found', receivedId: rawRoomId, normalizedId: roomId },
        404,
      );
    }

    // ✅ JS includes check — avoids Prisma array filter quirks
    if (!room.participants.includes(userId)) {
      return c.json(
        { err: 'Not a participant', userId, participants: room.participants },
        403,
      );
    }

    const messages = await prisma.chatMessage.findMany({
      where: { roomId },
      orderBy: { timestamp: 'asc' },
    });

    return c.json(messages.map(formatMessage));
  }

  /**
   * POST /chat/rooms/:roomId/messages
   */
  async sendMessage(c: Context) {
    const userId = c.get('userId') as string;
    const rawRoomId = c.req.param('roomId');

    if (!rawRoomId) {
      return c.json({ err: 'Room ID is required' }, 400);
    }

    // ✅ Normalize to lowercase to match Prisma's stored UUID format
    const roomId = rawRoomId.toLowerCase();

    const body = await c.req.json();
    const parsed = sendMessageSchema.safeParse(body);

    if (!parsed.success) {
      return c.json(
        { err: 'Invalid input', details: parsed.error.flatten() },
        400,
      );
    }

    const senderId = userId;
    const senderName =
      parsed.data.sender_name ??
      parsed.data.senderName ??
      (await resolveUserName(userId));
    const senderRole =
      parsed.data.sender_role ??
      parsed.data.senderRole ??
      (await resolveUserRole(userId));

    const room = await prisma.chatRoom.findUnique({
      where: { id: roomId },
    });

    if (!room) {
      return c.json(
        { err: 'Room not found', receivedId: rawRoomId, normalizedId: roomId },
        404,
      );
    }

    // ✅ JS includes check — avoids Prisma array filter quirks
    if (!room.participants.includes(userId)) {
      return c.json(
        { err: 'Not a participant', userId, participants: room.participants },
        403,
      );
    }

    const [msg] = await prisma.$transaction([
      prisma.chatMessage.create({
        data: {
          roomId, // ✅ guaranteed string, already normalized
          senderId,
          senderName,
          senderRole,
          content: parsed.data.content,
          status: 'sent',
        },
      }),
      prisma.chatRoom.update({
        where: { id: roomId },
        data: { lastActivity: new Date() },
      }),
    ]);

    const formattedMsg = formatMessage(msg);

    try {
      await triggerRoomEvent(
        roomId,
        'new-message',
        formattedMsg as unknown as Record<string, unknown>,
      );
      for (const participantId of room.participants) {
        await triggerUserEvent(
          participantId,
          'new-message',
          formattedMsg as unknown as Record<string, unknown>,
        );
      }
    } catch (err) {
      console.error('Pusher trigger failed (sendMessage):', err);
    }

    return c.json(formattedMsg, 201);
  }

  /**
   * PUT /chat/rooms/:roomId/read
   */
  async markRead(c: Context) {
    const userId = c.get('userId') as string;
    const rawRoomId = c.req.param('roomId');

    if (!rawRoomId) {
      return c.json({ err: 'Room ID is required' }, 400);
    }

    // ✅ Normalize to lowercase to match Prisma's stored UUID format
    const roomId = rawRoomId.toLowerCase();

    const room = await prisma.chatRoom.findUnique({
      where: { id: roomId },
    });

    if (!room) {
      return c.json({ err: 'Room not found' }, 404);
    }

    // ✅ JS includes check — avoids Prisma array filter quirks
    if (!room.participants.includes(userId)) {
      return c.json({ err: 'Not a participant' }, 403);
    }

    await prisma.chatRoomRead.upsert({
      where: {
        roomId_userId: { roomId, userId },
      },
      create: { roomId, userId, lastReadAt: new Date() },
      update: { lastReadAt: new Date() },
    });

    return c.json({ success: true });
  }

  /**
   * GET /chat/users
   */
  async getUsers(c: Context) {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        role: true,
        manager: { select: { name: true } },
        driver: { select: { name: true } },
        maintenance: { select: { name: true } },
      },
    });

    const result = users.map((u) => {
      let name = 'Unknown';
      if (u.role === 'MANAGER' && u.manager) name = u.manager.name;
      if (u.role === 'DRIVER' && u.driver) name = u.driver.name;
      if (u.role === 'MAINTENANCE' && u.maintenance) name = u.maintenance.name;
      if (u.role === 'SUPER_ADMIN') name = 'Admin';

      return {
        id: u.id,
        name,
        role: u.role.toLowerCase(),
        initials: name.charAt(0).toUpperCase(),
      };
    });

    return c.json(result);
  }
}
