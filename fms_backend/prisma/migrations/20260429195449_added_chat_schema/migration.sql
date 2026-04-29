-- CreateEnum
CREATE TYPE "ChatRoomType" AS ENUM ('DIRECT', 'GROUP', 'BROADCAST');

-- CreateTable
CREATE TABLE "vehicle_predictive_maintenance" (
    "id" TEXT NOT NULL,
    "engine_temp" INTEGER NOT NULL,
    "distance" INTEGER NOT NULL,
    "brake_events" INTEGER NOT NULL,
    "sharp_turns" INTEGER NOT NULL,
    "cargo_weight" DOUBLE PRECISION NOT NULL,
    "weather_temp" INTEGER NOT NULL,
    "humidity" INTEGER NOT NULL,
    "vehicleId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "vehicle_predictive_maintenance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "chat_rooms" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "avatar_initials" TEXT,
    "room_type" "ChatRoomType" NOT NULL DEFAULT 'GROUP',
    "participants" TEXT[],
    "participant_names" JSONB,
    "last_activity" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "chat_rooms_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "chat_messages" (
    "id" TEXT NOT NULL,
    "room_id" TEXT NOT NULL,
    "sender_id" TEXT NOT NULL,
    "sender_name" TEXT NOT NULL,
    "sender_role" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'sent',
    "is_starred" BOOLEAN NOT NULL DEFAULT false,
    "attachment_type" TEXT,
    "attachment_url" TEXT,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "chat_messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "chat_room_reads" (
    "id" TEXT NOT NULL,
    "room_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "last_read_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "chat_room_reads_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "chat_messages_room_id_idx" ON "chat_messages"("room_id");

-- CreateIndex
CREATE UNIQUE INDEX "chat_room_reads_room_id_user_id_key" ON "chat_room_reads"("room_id", "user_id");

-- AddForeignKey
ALTER TABLE "vehicle_predictive_maintenance" ADD CONSTRAINT "vehicle_predictive_maintenance_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "vehicles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_messages" ADD CONSTRAINT "chat_messages_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "chat_rooms"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_room_reads" ADD CONSTRAINT "chat_room_reads_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "chat_rooms"("id") ON DELETE CASCADE ON UPDATE CASCADE;
