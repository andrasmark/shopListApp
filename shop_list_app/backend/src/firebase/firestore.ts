import admin from "firebase-admin";
import * as dotenv from 'dotenv';
dotenv.config();

const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
const projectId = process.env.FIREBASE_PROJECT_ID;

admin.initializeApp({
  credential: admin.credential.cert({
    projectId: projectId,
    clientEmail: clientEmail,
    privateKey: privateKey,
  }),
});

const db = admin.firestore();
export { db };

  // import admin from "firebase-admin";
  // import firebaseConfig from "../firebaseConfig";

  // admin.initializeApp({
  //   credential: admin.credential.cert({
  //     projectId: firebaseConfig.app.options.projectId,
  //     clientEmail: "A TE CLIENT EMAIL-ED",
  //     privateKey: "A TE PRIVATE KEY-ED".replace(/\\n/g, "\n"),
  //   }),
  // });

  // const db = admin.firestore();
  // export { db };