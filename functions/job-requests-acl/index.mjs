import { Client, Databases, Permission, Role } from "node-appwrite";

export default async ({ req, res, log, error }) => {
  try {
    const doc = JSON.parse(req.payload || req.body || "{}");
    const dbId = process.env.APPWRITE_DATABASE_ID;
    const colId = process.env.APPWRITE_JOB_REQUESTS_ID;
    const endpoint = process.env.APPWRITE_ENDPOINT;
    const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID;
    const apiKey = process.env.APPWRITE_API_KEY;

    if (!doc?.$id) return res.json({ error: "no id" }, 400);
    const clientId = doc.clientId;
    const driverId = doc.driverId;
    if (!clientId || !driverId) return res.json({ error: "missing client/driver" }, 400);

    const c = new Client().setEndpoint(endpoint).setProject(projectId).setKey(apiKey);
    const db = new Databases(c);

    await db.updateDocument(dbId, colId, doc.$id, {}, [
      Permission.read(Role.user(clientId)),
      Permission.read(Role.user(driverId)),
      Permission.update(Role.user(clientId)),
      Permission.update(Role.user(driverId)),
      Permission.delete(Role.user(clientId)),
    ]);
    return res.send("OK");
  } catch (e) {
    error(e.message || String(e));
    return res.json({ error: e.message || String(e) }, 500);
  }
};
