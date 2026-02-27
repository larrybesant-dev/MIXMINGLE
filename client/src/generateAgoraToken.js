// Client helper to call generateAgoraToken
// Usage: import generateAgoraToken from './generateAgoraToken';
// generateAgoraToken({ roomId: 'room123', userId: 'user456' })
export default async function generateAgoraToken({ roomId, userId, endpoint }) {
  if (!roomId || !userId) {
    throw new Error("Missing required parameters: roomId and userId");
  }

  // If using Firebase callable, set endpoint to 'callable' and call accordingly.
  if (endpoint === "callable") {
    // Example for firebase v9 compat or v8 style; adapt to your firebase import
    const functions = window.firebase?.functions?.(); // ensure firebase is initialized
    if (!functions) throw new Error("Firebase functions not initialized");
    const generate = functions.httpsCallable("generateAgoraToken");
    const res = await generate({ roomId, userId });
    return res.data;
  }

  // Default: HTTP POST to Cloud Function URL
  const url = endpoint || "https://us-central1-YOUR_PROJECT.cloudfunctions.net/generateAgoraToken";
  const resp = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ roomId, userId }),
  });
  if (!resp.ok) {
    const text = await resp.text().catch(() => null);
    let body;
    try {
      body = JSON.parse(text);
    } catch {
      body = text;
    }
    const err = new Error("generateAgoraToken failed");
    err.status = resp.status;
    err.body = body;
    throw err;
  }
  return resp.json();
}
