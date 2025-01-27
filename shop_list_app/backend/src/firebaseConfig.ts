import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyDORoHNqwllIrLwR4EBsa7AQtf2aEe4QLQ",
  authDomain: "shoplistapp-6faad.firebaseapp.com",
  projectId: "shoplistapp-6faad",
  storageBucket: "shoplistapp-6faad.firebasestorage.app",
  messagingSenderId: "637551684753",
  appId: "1:637551684753:web:84899d56f6ed60da722330",
  measurementId: "G-FVYHRFE6Q3"
};

const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
const auth = getAuth(app);
const db = getFirestore(app);

export default { app, analytics, auth, db };