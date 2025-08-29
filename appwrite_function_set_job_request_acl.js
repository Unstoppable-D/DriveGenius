// Appwrite Function: Set Job Request ACL
// This function tightens document permissions after creation
// Trigger: databases.*.collections.job_requests.documents.create

import { Client, Databases, Permission, Role } from "appwrite";

export default async ({ req, res, log, error }) => {
  try {
    // Parse the document payload from Appwrite
    const payload = JSON.parse(req.payload);
    const dbId = process.env.APPWRITE_DATABASE_ID;
    const colId = process.env.APPWRITE_JOB_REQUESTS_ID;

    // Extract user IDs from the document
    const clientId = payload.clientId;
    const driverId = payload.driverId;
    const docId = payload.$id;

    log(`Setting ACL for job request ${docId}: client=${clientId}, driver=${driverId}`);

    // Initialize Appwrite client with API key
    const client = new Client()
      .setEndpoint(process.env.APPWRITE_ENDPOINT)
      .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
      .setKey(process.env.APPWRITE_API_KEY); // server key

    const databases = new Databases(client);

    // Update document with restrictive permissions
    // Only the client and driver can read/update this document
    await databases.updateDocument(dbId, colId, docId, {}, [
      Permission.read(Role.user(clientId)),
      Permission.read(Role.user(driverId)),
      Permission.update(Role.user(clientId)),
      Permission.update(Role.user(driverId)),
      Permission.delete(Role.user(clientId)), // Only client can delete
    ]);

    log(`✅ ACL set successfully for job request ${docId}`);
    return res.send("OK");

  } catch (e) {
    error(`Failed to set ACL: ${e.message}`);
    log(`Error details: ${JSON.stringify(e)}`);
    return res.json({ error: e.message }, 500);
  }
};
