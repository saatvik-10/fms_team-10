import { z } from 'zod';

export const createRoomSchema = z.object({
  targetId: z.string().trim().min(1, 'Target user ID is required'),
  senderId: z.string().trim().min(1, 'Sender ID is required'),
  senderName: z.string().trim().min(1, 'Sender name is required'),
  senderRole: z.string().trim().min(1, 'Sender role is required'),
  message: z.string().trim().min(1, 'Initial message is required').max(5000),
});

export const sendMessageSchema = z.object({
  content: z.string().trim().min(1, 'Message content is required').max(5000),
  sender_id: z.string().trim().min(1).optional(),
  sender_name: z.string().trim().min(1).optional(),
  sender_role: z.string().trim().min(1).optional(),
  room_id: z.string().trim().optional(),
  // Also accept camelCase variants from the iOS client
  senderId: z.string().trim().min(1).optional(),
  senderName: z.string().trim().min(1).optional(),
  senderRole: z.string().trim().min(1).optional(),
  roomId: z.string().trim().optional(),
});

export type CreateRoomInput = z.infer<typeof createRoomSchema>;
export type SendMessageInput = z.infer<typeof sendMessageSchema>;
