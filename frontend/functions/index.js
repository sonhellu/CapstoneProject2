const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp }     = require("firebase-admin/app");
const { getFirestore }      = require("firebase-admin/firestore");
const { getMessaging }      = require("firebase-admin/messaging");

initializeApp();

const db  = getFirestore();
const fcm = getMessaging();

// ── Helper ────────────────────────────────────────────────────────────────────

async function sendPush(token, title, body, data = {}) {
  if (!token) return;
  try {
    await fcm.send({
      token,
      notification: { title, body },
      data,
      android: { priority: "high" },
      apns: {
        payload: { aps: { sound: "default", badge: 1 } },
      },
    });
  } catch (err) {
    // Token may be stale — log but don't crash the function.
    console.error("FCM send error:", err.code, err.message);
  }
}

// ── 1. New chat request → notify receiver ─────────────────────────────────────

exports.onChatRequestCreated = onDocumentCreated(
  "chat_requests/{requestId}",
  async (event) => {
    const data = event.data.data();
    if (data.status !== "pending") return;

    const receiverSnap = await db.collection("users").doc(data.receiverId).get();
    const token        = receiverSnap.data()?.fcmToken;
    const senderName   = data.senderInfo?.displayName ?? "Someone";

    await sendPush(
      token,
      senderName,
      "Wants to connect with you on HiCampus 👋",
      { type: "chat_request", convId: "", requestId: event.params.requestId }
    );
  }
);

// ── 2. New message → notify the other participant ─────────────────────────────

exports.onMessageCreated = onDocumentCreated(
  "conversations/{convId}/messages/{msgId}",
  async (event) => {
    const msg = event.data.data();

    // Skip system messages and empty content.
    if (msg.senderId === "system" || !msg.content) return;

    const convSnap = await db
      .collection("conversations")
      .doc(event.params.convId)
      .get();

    if (!convSnap.exists) return;
    const conv = convSnap.data();

    // Recipient = the participant who did NOT send this message.
    const recipientUid = conv.participants.find((p) => p !== msg.senderId);
    if (!recipientUid) return;

    const recipientSnap = await db.collection("users").doc(recipientUid).get();
    const token         = recipientSnap.data()?.fcmToken;
    const senderName    = conv.participantInfo?.[msg.senderId]?.displayName ?? "New message";

    // Truncate long messages in notification body.
    const body = msg.content.length > 60
      ? msg.content.substring(0, 60) + "…"
      : msg.content;

    await sendPush(
      token,
      senderName,
      body,
      { type: "message", convId: event.params.convId }
    );
  }
);
