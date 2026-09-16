import { initializeApp, getApps, type FirebaseApp } from "firebase/app";
import { getAuth, signInWithCustomToken, signOut, type Auth } from "firebase/auth";

function webConfig() {
  const apiKey = process.env.NEXT_PUBLIC_FIREBASE_API_KEY || "";
  const projectId = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || "";
  if (!apiKey || !projectId) return null;
  return {
    apiKey,
    authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || `${projectId}.firebaseapp.com`,
    projectId,
    storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || "",
    messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || "",
    appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || "",
  };
}

function firebaseApp(): FirebaseApp | null {
  const config = webConfig();
  if (!config || typeof window === "undefined") return null;
  return getApps()[0] ?? initializeApp(config);
}

export function firebaseAuth(): Auth | null {
  const app = firebaseApp();
  return app ? getAuth(app) : null;
}

export async function consumeCustomToken(customToken: string | null | undefined): Promise<"firebase" | "dev"> {
  if (!customToken) return "dev";
  const auth = firebaseAuth();
  if (!auth) return "dev";
  await signInWithCustomToken(auth, customToken);
  return "firebase";
}

export async function signOutFirebase(): Promise<void> {
  const auth = firebaseAuth();
  if (!auth) return;
  await signOut(auth);
}
