-- Voice messages: the clip's length for direct messages, and the audio file
-- for Vibe room chat messages of kind "voice".
ALTER TABLE "Message" ADD COLUMN "mediaDurationMs" INTEGER;

ALTER TABLE "VibeRoomMessage" ADD COLUMN "mediaUrl" TEXT;
ALTER TABLE "VibeRoomMessage" ADD COLUMN "mediaPublicId" TEXT;
ALTER TABLE "VibeRoomMessage" ADD COLUMN "mediaDurationMs" INTEGER;
