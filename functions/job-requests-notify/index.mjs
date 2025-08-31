import { Client, Databases, Permission, Role } from "node-appwrite";

export default async ({ req, res, log, error }) => {
  try {
    const payload = JSON.parse(req.payload || req.body || "{}");
    const status   = payload?.status;
    const clientId = payload?.clientId;
    if (!payload?.$id || !clientId || !status) return res.json({ skip: true }, 200);
    if (!["ACCEPTED","REJECTED"].includes(status)) return res.json({ skip: true }, 200);

    const endpoint  = process.env.APPWRITE_ENDPOINT;
    const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID;
    const apiKey    = process.env.APPWRITE_API_KEY;
    const dbId      = process.env.APPWRITE_DATABASE_ID;
    const colNot    = process.env.APPWRITE_NOTIFICATIONS_ID;

    const c = new Client().setEndpoint(endpoint).setProject(projectId).setKey(apiKey);
    const db = new Databases(c);

    const id = `${payload.$id}_${status}`;
    const title = status === "ACCEPTED" ? "Trip accepted" : "Trip rejected";
    const body  = status === "ACCEPTED" && payload.estimatedPickupAt ? `ETA pickup: ${payload.estimatedPickupAt}` : "";

    try {
      await db.createDocument(dbId, colNot, id, {
        userId: clientId,
        jobRequestId: payload.$id,
        type: status === "ACCEPTED" ? "JOB_ACCEPTED" : "JOB_REJECTED",
        title, body,
        status: "UNREAD",
        createdAt: new Date().toISOString()
      }, [
        Permission.read(Role.user(clientId)),
        Permission.update(Role.user(clientId)),
        Permission.delete(Role.user(clientId))
      ]);
    } catch (e) {
      if (e?.code !== 409) throw e;
      await db.updateDocument(dbId, colNot, id, {
        userId: clientId,
        jobRequestId: payload.$id,
        type: status === "ACCEPTED" ? "JOB_ACCEPTED" : "JOB_REJECTED",
        title, body,
        status: "UNREAD",
        createdAt: new Date().toISOString()
      }, [
        Permission.read(Role.user(clientId)),
        Permission.update(Role.user(clientId)),
        Permission.delete(Role.user(clientId))
      ]);
    }

    return res.send("OK");
  } catch (e) {
    error(e?.message || String(e));
    return res.json({ error: e?.message || String(e) }, 500);
  }
};
