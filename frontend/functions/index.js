const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onRequest }         = require("firebase-functions/v2/https");
const { initializeApp }     = require("firebase-admin/app");
const { getFirestore }      = require("firebase-admin/firestore");
const { getMessaging }      = require("firebase-admin/messaging");

initializeApp();

const db  = getFirestore();
const fcm = getMessaging();

// ── Helper ────────────────────────────────────────────────────────────────────

const STALE_TOKEN_ERRORS = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);

async function clearUserFcmToken(uid) {
  if (!uid) return;
  try {
    await db.collection("users").doc(uid).set(
      { fcmToken: null },
      { merge: true },
    );
    console.info(`[FCM] Cleared stale token for uid=${uid}`);
  } catch (err) {
    console.error("[FCM] Failed to clear stale token:", uid, err.code, err.message);
  }
}

async function sendPush({ token, uid, title, body, data = {} }) {
  if (!token) {
    console.info(`[FCM] Skip push: missing token for uid=${uid ?? "unknown"}`);
    return { ok: false, reason: "missing-token" };
  }

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
    console.info(`[FCM] Push sent to uid=${uid ?? "unknown"}`);
    return { ok: true };
  } catch (err) {
    console.error("[FCM] Send error:", err.code, err.message);
    if (uid && STALE_TOKEN_ERRORS.has(err.code)) {
      await clearUserFcmToken(uid);
    }
    return { ok: false, reason: err.code ?? "unknown" };
  }
}

async function getUserToken(uid) {
  if (!uid) return null;

  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) {
    console.info(`[FCM] User doc not found for uid=${uid}`);
    return null;
  }

  const token = snap.data()?.fcmToken;
  if (typeof token !== "string" || token.trim().length === 0) {
    console.info(`[FCM] No valid fcmToken for uid=${uid}`);
    return null;
  }

  return token;
}

// ── 0. Papago proxy (CORS-safe for Flutter Web) ───────────────────────────────
//
// Browser cannot call Papago directly (no CORS headers).
// Flutter Web calls this function instead; mobile still calls Papago directly.

const PAPAGO_TRANSLATE = "https://papago.apigw.ntruss.com/nmt/v1/translation";
const PAPAGO_DETECT    = "https://papago.apigw.ntruss.com/langs/v1/dect";
const PAPAGO_ID        = "8qt8fd502n";
const PAPAGO_SECRET    = "lw3ljuXAXll7yTykpXMBxq8bRfKH1uo5ZHlxCw7q";
const PAPAGO_LANGS     = new Set(["ko", "en", "vi", "ja", "zh-CN"]);

function setCors(res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
}

function isSupportedPapagoLang(lang) {
  return typeof lang === "string" && PAPAGO_LANGS.has(lang);
}

exports.papagoProxy = onRequest({ invoker: "public" }, async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") { res.status(204).send(""); return; }
  if (req.method !== "POST")    { res.status(405).send("Method Not Allowed"); return; }

  const { action, text, source, target } = req.body ?? {};
  if (!text) { res.status(400).json({ error: "missing text" }); return; }
  if (action === "detect") {
    // OK
  } else {
    if (!isSupportedPapagoLang(source) || !isSupportedPapagoLang(target)) {
      res.status(400).json({ error: "unsupported source/target language" });
      return;
    }
  }

  try {
    const isDetect = action === "detect";
    const url      = isDetect ? PAPAGO_DETECT : PAPAGO_TRANSLATE;
    const body     = isDetect
      ? new URLSearchParams({ query: text })
      : new URLSearchParams({ source, target, text });

    const upstream = await fetch(url, {
      method:  "POST",
      headers: {
        "X-NCP-APIGW-API-KEY-ID": PAPAGO_ID,
        "X-NCP-APIGW-API-KEY":    PAPAGO_SECRET,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body,
    });

    const data = await upstream.json();
    res.status(upstream.status).json(data);
  } catch (err) {
    console.error("papagoProxy error:", err);
    res.status(500).json({ error: err.message });
  }
});

// ── 1. New chat request → notify receiver ─────────────────────────────────────

exports.onChatRequestCreated = onDocumentCreated(
  "chat_requests/{requestId}",
  async (event) => {
    if (!event.data) {
      console.info("[ChatRequest] Skip: missing event data");
      return;
    }

    const data = event.data.data();
    if (data.status !== "pending") return;
    if (!data.receiverId) {
      console.info("[ChatRequest] Skip: missing receiverId");
      return;
    }

    const token        = await getUserToken(data.receiverId);
    const senderName   = data.senderInfo?.displayName ?? "Someone";

    await sendPush(
      {
        token,
        uid: data.receiverId,
        title: senderName,
        body: "Wants to connect with you on HiCampus 👋",
        data: {
          type: "chat_request",
          convId: "",
          requestId: event.params.requestId,
        },
      },
    );
  }
);

// ── 2. New message → notify the other participant ─────────────────────────────

exports.onMessageCreated = onDocumentCreated(
  "conversations/{convId}/messages/{msgId}",
  async (event) => {
    if (!event.data) {
      console.info("[Message] Skip: missing event data");
      return;
    }

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
    const participants = Array.isArray(conv.participants) ? conv.participants : [];
    const recipientUid = participants.find((p) => p !== msg.senderId);
    if (!recipientUid) return;

    const token         = await getUserToken(recipientUid);
    const senderName    = conv.participantInfo?.[msg.senderId]?.displayName ?? "New message";

    // Truncate long messages in notification body.
    const body = msg.content.length > 60
      ? msg.content.substring(0, 60) + "…"
      : msg.content;

    await sendPush(
      {
        token,
        uid: recipientUid,
        title: senderName,
        body,
        data: { type: "message", convId: event.params.convId },
      },
    );
  }
);
