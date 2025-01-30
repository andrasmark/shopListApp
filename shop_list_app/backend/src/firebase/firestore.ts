import admin from "firebase-admin";
import firebaseConfig from "../firebaseConfig";

admin.initializeApp({
  credential: admin.credential.cert({
    projectId: firebaseConfig.app.options.projectId,
    clientEmail: "A TE CLIENT EMAIL-ED",
    privateKey: "A TE PRIVATE KEY-ED".replace(/\\n/g, "\n"),
  }),
});

const db = admin.firestore();
export { db };