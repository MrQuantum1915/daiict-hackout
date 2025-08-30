import { Outlet } from 'react-router-dom'
import Sidebar from '../navigation/Sidebar'
import Header from '../navigation/Header'
import { useState, useEffect } from 'react'
import { useAuth } from '@/hooks/useAuth'
import { initializeMessaging } from '@/lib/firebase'
import { getToken } from 'firebase/messaging'
import { useToast } from '@/hooks/useToast'

const DashboardLayout = () => {
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const { user } = useAuth()
  const { toast } = useToast()

  // Initialize push notifications
  useEffect(() => {
    const setupPushNotifications = async () => {
      try {
        const messaging = await initializeMessaging()
        if (!messaging) return

        // Request permission and get token
        const permission = await Notification.requestPermission()
        if (permission === 'granted') {
          // Get token and save it to the database for the current user
          const token = await getToken(messaging, {
            vapidKey: import.meta.env.VITE_FIREBASE_VAPID_KEY,
          })
          
          console.log('FCM Token:', token)
          
          // Here you would typically save this token to your database
          // associated with the current user
          
          // Set up foreground message handler
          // onMessage(messaging, (payload) => {
          //   toast({
          //     title: payload.notification?.title || 'New Notification',
          //     description: payload.notification?.body,
          //     duration: 5000,
          //   })
          // })
        }
      } catch (error) {
        console.error('Error setting up push notifications:', error)
      }
    }

    if (user) {
      setupPushNotifications()
    }
  }, [user, toast])

  return (
    <div className="flex h-screen overflow-hidden">
      {/* Sidebar */}
      <Sidebar open={sidebarOpen} setOpen={setSidebarOpen} />
      
      {/* Main Content */}
      <div className="flex flex-col flex-1 w-0 overflow-hidden">
        <Header sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen} />
        
        <main className="relative flex-1 overflow-y-auto focus:outline-none">
          <div className="py-6">
            <div className="px-4 mx-auto max-w-7xl sm:px-6 md:px-8">
              <Outlet />
            </div>
          </div>
        </main>
      </div>
    </div>
  )
}

export default DashboardLayout

