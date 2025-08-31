import { useState, useEffect } from 'react'
import { collection, query, orderBy, limit, onSnapshot, doc, updateDoc } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { formatDate } from '@/lib/utils'
import { Bell, CheckCircle, AlertCircle, FileText, MapPin, User } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { useToast } from '@/hooks/useToast'

interface Notification {
  id: string
  title: string
  message: string
  type: 'report' | 'system' | 'chat'
  read: boolean
  reportId?: string
  reportLocation?: string
  createdAt: any // Firestore timestamp
}

const NotificationsPage = () => {
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [loading, setLoading] = useState(true)
  const { toast } = useToast()

  useEffect(() => {
    // Subscribe to notifications
    const notificationsRef = collection(db, 'notifications')
    const notificationsQuery = query(
      notificationsRef,
      orderBy('createdAt', 'desc')
    )

    const unsubscribe = onSnapshot(notificationsQuery, (snapshot) => {
      const fetchedNotifications: Notification[] = []
      snapshot.forEach((doc) => {
        fetchedNotifications.push({ id: doc.id, ...doc.data() } as Notification)
      })
      setNotifications(fetchedNotifications)
      setLoading(false)
    }, (error) => {
      console.error('Error fetching notifications:', error)
      setLoading(false)
      
      // For demo purposes, set mock data if there's an error
      setMockData()
    })

    return () => unsubscribe()
  }, [])

  const setMockData = () => {
    // Mock data for demonstration
    const mockNotifications: Notification[] = [
      {
        id: '1',
        title: 'New Report Submitted',
        message: 'John Doe submitted a new report about mangrove damage in Miami Beach.',
        type: 'report',
        read: false,
        reportId: '1',
        reportLocation: 'Miami Beach, FL',
        createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 30) }
      },
      {
        id: '2',
        title: 'Report Status Updated',
        message: 'The report from Jane Smith has been marked as "In Progress".',
        type: 'report',
        read: false,
        reportId: '2',
        reportLocation: 'Coral Gables, FL',
        createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 2) }
      },
      {
        id: '3',
        title: 'New Support Message',
        message: 'Robert Johnson sent a message: "When will someone check the reported issue?"',
        type: 'chat',
        read: true,
        createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 5) }
      },
      {
        id: '4',
        title: 'System Maintenance',
        message: 'The system will undergo maintenance tonight from 2 AM to 4 AM EST.',
        type: 'system',
        read: true,
        createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 24) }
      },
      {
        id: '5',
        title: 'New Report Submitted',
        message: 'Maria Garcia submitted a new report about pollution affecting mangroves.',
        type: 'report',
        read: false,
        reportId: '4',
        reportLocation: 'Aventura, FL',
        createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 26) }
      },
      {
        id: '6',
        title: 'New Support Message',
        message: 'David Wilson sent a message: "Thanks for the quick response to my report!"',
        type: 'chat',
        read: true,
        createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 48) }
      },
      {
        id: '7',
        title: 'Report Resolved',
        message: 'The report about invasive species has been marked as "Resolved".',
        type: 'report',
        read: true,
        reportId: '5',
        reportLocation: 'Miami Shores, FL',
        createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 72) }
      }
    ]
    
    setNotifications(mockNotifications)
  }

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case 'report':
        return <FileText className="w-5 h-5 text-mangrove-500" />
      case 'system':
        return <AlertCircle className="w-5 h-5 text-blue-500" />
      case 'chat':
        return <User className="w-5 h-5 text-purple-500" />
      default:
        return <Bell className="w-5 h-5 text-gray-500" />
    }
  }

  const markAsRead = async (notificationId: string) => {
    try {
      // In a real app, update the notification in Firestore
      // const notificationRef = doc(db, 'notifications', notificationId)
      // await updateDoc(notificationRef, { read: true })
      
      // For demo, update the local state
      const updatedNotifications = notifications.map(notification => 
        notification.id === notificationId ? { ...notification, read: true } : notification
      )
      setNotifications(updatedNotifications)
      
      toast({
        title: 'Notification marked as read',
        description: 'The notification has been marked as read.',
      })
    } catch (error) {
      console.error('Error marking notification as read:', error)
      toast({
        title: 'Update Failed',
        description: 'Failed to mark notification as read. Please try again.',
        variant: 'destructive',
      })
    }
  }

  const markAllAsRead = async () => {
    try {
      // In a real app, update all notifications in Firestore
      // const batch = writeBatch(db)
      // notifications.forEach(notification => {
      //   if (!notification.read) {
      //     const notificationRef = doc(db, 'notifications', notification.id)
      //     batch.update(notificationRef, { read: true })
      //   }
      // })
      // await batch.commit()
      
      // For demo, update the local state
      const updatedNotifications = notifications.map(notification => ({ ...notification, read: true }))
      setNotifications(updatedNotifications)
      
      toast({
        title: 'All notifications marked as read',
        description: 'All notifications have been marked as read.',
      })
    } catch (error) {
      console.error('Error marking all notifications as read:', error)
      toast({
        title: 'Update Failed',
        description: 'Failed to mark all notifications as read. Please try again.',
        variant: 'destructive',
      })
    }
  }

  const unreadCount = notifications.filter(notification => !notification.read).length

  return (
    <div>
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-gray-900">Notifications</h1>
        {unreadCount > 0 && (
          <Button 
            variant="outline" 
            size="sm"
            onClick={markAllAsRead}
          >
            Mark all as read
          </Button>
        )}
      </div>
      
      <div className="mt-6 overflow-hidden bg-white rounded-lg shadow">
        <div className="px-4 py-5 border-b sm:px-6">
          <h2 className="text-lg font-medium text-gray-900">
            {unreadCount} Unread {unreadCount === 1 ? 'Notification' : 'Notifications'}
          </h2>
        </div>
        
        <ul className="divide-y divide-gray-200">
          {loading ? (
            <li className="px-6 py-4 text-center text-gray-500">Loading notifications...</li>
          ) : notifications.length === 0 ? (
            <li className="px-6 py-4 text-center text-gray-500">No notifications found</li>
          ) : (
            notifications.map((notification) => (
              <li 
                key={notification.id} 
                className={`px-4 py-4 ${!notification.read ? 'bg-mangrove-50' : ''}`}
              >
                <div className="flex items-start">
                  <div className="flex-shrink-0 pt-0.5">
                    {getNotificationIcon(notification.type)}
                  </div>
                  <div className="flex-1 ml-3">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium text-gray-900">
                        {notification.title}
                      </p>
                      <p className="text-xs text-gray-500">
                        {formatDate(notification.createdAt.toDate())}
                      </p>
                    </div>
                    <p className="mt-1 text-sm text-gray-600">
                      {notification.message}
                    </p>
                    
                    {notification.type === 'report' && notification.reportLocation && (
                      <div className="flex items-center mt-2 text-xs text-gray-500">
                        <MapPin className="w-4 h-4 mr-1 text-gray-400" />
                        {notification.reportLocation}
                      </div>
                    )}
                    
                    <div className="flex mt-2 space-x-2">
                      {notification.type === 'report' && notification.reportId && (
                        <Button 
                          variant="outline" 
                          size="sm"
                          className="text-xs"
                          onClick={() => {
                            // In a real app, navigate to the report details
                            toast({
                              title: 'View Report',
                              description: `Navigating to report #${notification.reportId}`,
                            })
                          }}
                        >
                          View Report
                        </Button>
                      )}
                      
                      {!notification.read && (
                        <Button 
                          variant="ghost" 
                          size="sm"
                          className="text-xs"
                          onClick={() => markAsRead(notification.id)}
                        >
                          Mark as Read
                        </Button>
                      )}
                    </div>
                  </div>
                </div>
              </li>
            ))
          )}
        </ul>
      </div>
    </div>
  )
}

export default NotificationsPage

