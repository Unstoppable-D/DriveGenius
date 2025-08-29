import { Client, Databases, Permission, Role } from "node-appwrite";

export default async ({ req, res, log, error }) => {
  try {
    const payloadRaw = req.payload || req.body || "{}";
    const doc = JSON.parse(payloadRaw); // updated job_requests doc

    const dbId   = process.env.APPWRITE_DATABASE_ID;
    const colReq = process.env.APPWRITE_JOB_REQUESTS_ID;      // job_requests
    const colNot = process.env.APPWRITE_NOTIFICATIONS_ID;     // notifications
    const endpoint = process.env.APPWRITE_ENDPOINT || "https://cloud.appwrite.io/v1";
    const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID;
    const apiKey = process.env.APPWRITE_API_KEY;

    const status = doc?.status;
    const clientId = doc?.clientId;
    if (!doc?.$id || !clientId || !status) {
      return res.json({ skip: "missing fields" }, 200);
    }
    if (!["ACCEPTED", "REJECTED"].includes(status)) {
      return res.json({ skip: "status irrelevant" }, 200);
    }

    const title = status === "ACCEPTED" ? "Trip accepted" : "Trip rejected";
    let body = "";
    if (status === "ACCEPTED" && doc.estimatedPickupAt) {
      body = `ETA pickup: ${doc.estimatedPickupAt}`;
    }

    const client = new Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setKey(apiKey);

    const databases = new Databases(client);

    // Upsert leaf notification doc (idempotent)
    const notifId = `${doc.$id}_${status}`;
    try {
      await databases.createDocument(
        dbId,
        colNot,
        notifId,
        {
          userId: clientId,
          jobRequestId: doc.$id,
          type: status === "ACCEPTED" ? "JOB_ACCEPTED" : "JOB_REJECTED",
          title,
          body,
          status: "UNREAD",
          createdAt: new Date().toISOString(),
        },
        [
          Permission.read(Role.user(clientId)),
          Permission.update(Role.user(clientId)),
          Permission.delete(Role.user(clientId)),
        ]
      );
    } catch (e) {
      // If exists, update instead
      if (e?.code !== 409) throw e;
      await databases.updateDocument(
        dbId,
        colNot,
        notifId,
        {
          userId: clientId,
          jobRequestId: doc.$id,
          type: status === "ACCEPTED" ? "JOB_ACCEPTED" : "JOB_REJECTED",
          title,
          body,
          status: "UNREAD",
          createdAt: new Date().toISOString(),
        },
        [
          Permission.read(Role.user(clientId)),
          Permission.update(Role.user(clientId)),
          Permission.delete(Role.user(clientId)),
        ]
      );
    }

    return res.send("OK");
  } catch (e) {
    error(`notify failed: ${e?.message || e}`);
    return res.json({ error: e?.message || String(e) }, 500);
  }
};
