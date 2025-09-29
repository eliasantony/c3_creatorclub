import { initializeApp, type FirebaseApp } from 'firebase/app'
import { initializeAppCheck, ReCaptchaV3Provider } from 'firebase/app-check'
import { getAuth, connectAuthEmulator, type Auth } from 'firebase/auth'
import { getFirestore, connectFirestoreEmulator, type Firestore } from 'firebase/firestore'
import { getFunctions, connectFunctionsEmulator, httpsCallable, type Functions } from 'firebase/functions'

let app: FirebaseApp | undefined
let authInst: Auth | undefined
let dbInst: Firestore | undefined
let functionsInst: Functions | undefined
let emulatorsConnected = false
let appCheckInitialized = false

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
    // Optionally initialize App Check (helps avoid 403/CORS when enforcement is enabled)
    maybeInitAppCheck()
  }
  return app
}

export function getAuthInstance(): Auth {
  if (!authInst) {
    authInst = getAuth(getFirebaseApp())
    maybeConnectEmulators()
  }
  return authInst
}
export function getDb(): Firestore {
  if (!dbInst) {
    dbInst = getFirestore(getFirebaseApp())
    maybeConnectEmulators()
  }
  return dbInst
}
export function getFunctionsInstance(): Functions {
  if (!functionsInst) {
    const region = process.env.NEXT_PUBLIC_FIREBASE_FUNCTIONS_REGION ?? 'us-central1'
    functionsInst = getFunctions(getFirebaseApp(), region)
    maybeConnectEmulators()
  }
  return functionsInst
}

export function call<I, O>(name: string) {
  return async (data: I) => {
    const callable = httpsCallable<I, O>(getFunctionsInstance(), name)
    const res = await callable(data).catch((err: any) => {
      // Improve debuggability when auth/claims/region issues occur
      const code = err?.code ?? 'unknown';
      const details = err?.details ?? err?.message ?? err;
      console.error(`[functions] ${name} failed:`, code, details);
      throw err;
    });
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

function maybeConnectEmulators() {
  if (typeof window === 'undefined') return // only connect in browser
  if (emulatorsConnected) return
  const use = process.env.NEXT_PUBLIC_USE_FIREBASE_EMULATORS === '1' || process.env.NEXT_PUBLIC_USE_FIREBASE_EMULATORS === 'true'
  if (!use) return
  try {
    if (authInst) connectAuthEmulator(authInst, 'http://localhost:9099', { disableWarnings: true })
    if (dbInst) connectFirestoreEmulator(dbInst, 'localhost', 8080)
    if (functionsInst) connectFunctionsEmulator(functionsInst, 'localhost', 5001)
    emulatorsConnected = true
    // eslint-disable-next-line no-console
    console.info('[firebase] Connected to emulators')
  } catch (e) {
    // eslint-disable-next-line no-console
    console.warn('[firebase] Emulator connect failed', e)
  }
}

function maybeInitAppCheck() {
  if (typeof window === 'undefined') return // client-only
  if (appCheckInitialized) return
  const enabled = process.env.NEXT_PUBLIC_ENABLE_APPCHECK === '1' || process.env.NEXT_PUBLIC_ENABLE_APPCHECK === 'true'
  const siteKey = process.env.NEXT_PUBLIC_RECAPTCHA_V3_SITE_KEY
  try {
    if (enabled && !siteKey) {
      // eslint-disable-next-line no-console
      console.warn('[firebase] App Check enabled but NEXT_PUBLIC_RECAPTCHA_V3_SITE_KEY is missing — skipping initialization')
    }
    if (enabled && siteKey) {
      const debugToken = process.env.NEXT_PUBLIC_APPCHECK_DEBUG_TOKEN
      if (debugToken) {
        // Set App Check debug token. If 'true' or 'auto', enable auto-generated token mode.
        if (debugToken === 'true' || debugToken === 'auto') {
          ;(self as unknown as { FIREBASE_APPCHECK_DEBUG_TOKEN?: boolean }).FIREBASE_APPCHECK_DEBUG_TOKEN = true
        } else {
          ;(self as unknown as { FIREBASE_APPCHECK_DEBUG_TOKEN?: string }).FIREBASE_APPCHECK_DEBUG_TOKEN = debugToken
        }
      }
      initializeAppCheck(getFirebaseApp(), {
        provider: new ReCaptchaV3Provider(siteKey),
        isTokenAutoRefreshEnabled: true,
      })
      appCheckInitialized = true
      // eslint-disable-next-line no-console
      console.info('[firebase] App Check initialized')
    }
  } catch (e) {
    // eslint-disable-next-line no-console
    console.warn('[firebase] App Check init failed (continuing without it)', e)
  }
}
