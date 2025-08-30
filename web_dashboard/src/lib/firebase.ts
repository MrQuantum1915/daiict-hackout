import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'
import { getStorage } from 'firebase/storage'
import { getMessaging, isSupported } from 'firebase/messaging'

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyCX6raL-R8YskqX9hU7tLBWuakI4Sx1xeM",
  authDomain: "dashboard-30e6b.firebaseapp.com",
  projectId: "dashboard-30e6b",
  storageBucket: "dashboard-30e6b.firebasestorage.app",
  messagingSenderId: "523380052030",
  appId: "1:523380052030:web:87940c22083e064914c16f",
  measurementId: "G-3B6LDY1X22"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig)

// Initialize Firebase services
export const auth = getAuth(app)
export const db = getFirestore(app)
export const storage = getStorage(app)

// Initialize Firebase Cloud Messaging and get a reference to the service
export const initializeMessaging = async () => {
  try {
    const isSupportedBrowser = await isSupported()
    if (isSupportedBrowser) {
      return getMessaging(app)
    }
    console.log('Firebase messaging is not supported in this browser')
    return null
  } catch (error) {
    console.error('Error initializing Firebase messaging:', error)
    return null
  }
}

export default app

