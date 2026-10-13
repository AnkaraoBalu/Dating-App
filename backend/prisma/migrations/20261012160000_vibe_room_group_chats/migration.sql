-- Vibe rooms as group chats: per-member read position for unread counts,
-- and a message kind so "… joined the room" lines live in the chat history.
ALTER TABLE "VibeRoomMember" ADD COLUMN "lastReadAt" TIMESTAMP(3);

ALTER TABLE "VibeRoomMessage" ADD COLUMN "kind" VARCHAR(16) NOT NULL DEFAULT 'text';
