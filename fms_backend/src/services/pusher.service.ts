import Pusher from 'pusher';

const pusher = new Pusher({
  appId: process.env.PUSHER_APP_ID!,
  key: process.env.PUSHER_KEY!,
  secret: process.env.PUSHER_SECRET!,
  cluster: process.env.PUSHER_CLUSTER!,
  useTLS: true,
});

/**
 * Strips dashes and lowercases a UUID to match the iOS PusherService channel naming convention.
 * e.g. "A1B2C3D4-E5F6-..." → "a1b2c3d4e5f6..."
 */
function cleanId(id: string): string {
  return id.replace(/-/g, '').toLowerCase();
}

/**
 * Trigger an event on a chat room channel.
 * Channel format: chat_{cleanedRoomId}
 */
export async function triggerRoomEvent(
  roomId: string,
  event: string,
  data: Record<string, unknown>,
) {
  const channel = `chat_${cleanId(roomId)}`;
  await pusher.trigger(channel, event, data);
}

/**
 * Trigger an event on a user's personal channel.
 * Channel format: user_{cleanedUserId}
 */
export async function triggerUserEvent(
  userId: string,
  event: string,
  data: Record<string, unknown>,
) {
  const channel = `user_${cleanId(userId)}`;
  await pusher.trigger(channel, event, data);
}
