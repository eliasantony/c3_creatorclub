// functions/src/scripts/setAdminRole.ts
import * as admin from "firebase-admin";
import { readFileSync } from "fs";

// Load service account key
const serviceAccount = JSON.parse(
  readFileSync("serviceAccount.json", "utf8")
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
});

async function main() {
  const uid = "UY8hXkemtLgfUZHaNrf8e7IQLzB3"; // your user’s UID
  await admin.auth().setCustomUserClaims(uid, { role: "superadmin" });
  console.log(`✅ User ${uid} is now a superadmin`);
}

main().catch(console.error);