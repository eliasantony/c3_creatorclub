import { initializeApp, getApps, type FirebaseApp } from 'firebase/app'
import { getAuth, type Auth } from 'firebase/auth'
import { getFirestore, type Firestore } from 'firebase/firestore'
import { getFunctions, httpsCallable, type Functions } from 'firebase/functions'

let app: FirebaseApp | undefined

export function getFirebaseApp(): FirebaseApp {
  if (!app) {
    if (!isFirebaseConfigured()) {
      throw new Error('Firebase is not configured')
    }
    const instance = initializeApp({
      apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY!,
      authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN!,
      projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID!,
      storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET!,
      messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID!,
      appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID!,
    })
    app = instance
  }
  return app
}

export function getAuthInstance(): Auth {
  return getAuth(getFirebaseApp())
}
export function getDb(): Firestore {
  return getFirestore(getFirebaseApp())
}
export function getFunctionsInstance(): Functions {
  return getFunctions(getFirebaseApp())
}

export function call<I, O>(name: string) {
  return async (data: I) => {
    const callable = httpsCallable<I, O>(getFunctionsInstance(), name)
    const res = await callable(data)
    return res.data
  }
}

export function isFirebaseConfigured() {
  return Boolean(
    process.env.NEXT_PUBLIC_FIREBASE_API_KEY &&
      process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN &&
      process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID &&
      process.env.NEXT_PUBLIC_FIREBASE_APP_ID
  )
}
