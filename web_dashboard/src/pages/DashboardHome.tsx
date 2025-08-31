import { useState, useEffect } from 'react'
import { collection, query, orderBy, limit, onSnapshot } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { formatDate } from '@/lib/utils'
import { FileText, Users, MapPin, CheckCircle, AlertCircle, Clock } from 'lucide-react'
import { Link } from 'react-router-dom'

interface Report {
  id: string
  userId: string
  userName: string
  location: {
    latitude: number
    longitude: number
    address?: string
  }
  description: string
  photoURL?: string
  status: 'Pending' | 'In Progress' | 'Resolved'
  createdAt: any // Firestore timestamp
}

const DashboardHome = () => {
  const [recentReports, setRecentReports] = useState<Report[]>([])
  const [stats, setStats] = useState({
    totalReports: 0,
    pendingReports: 0,
    resolvedReports: 0,
    activeUsers: 0
  })
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Subscribe to recent reports
    const reportsRef = collection(db, 'reports')
    const recentReportsQuery = query(
      reportsRef,
      orderBy('createdAt', 'desc'),
      limit(5)
    )

    const unsubscribe = onSnapshot(recentReportsQuery, (snapshot) => {
      const reports: Report[] = []
      snapshot.forEach((doc) => {
        reports.push({ id: doc.id, ...doc.data() } as Report)
      })
      setRecentReports(reports)
      setLoading(false)
    }, (error) => {
      console.error('Error fetching recent reports:', error)
      setLoading(false)
      
      // For demo purposes, set mock data if there's an error
      setMockData()
    })

    // Fetch stats
    fetchStats()

    return () => unsubscribe()
  }, [])

  const fetchStats = async () => {
    try {
      // In a real app, you would fetch these stats from your database
      // For now, we'll use mock data
      setStats({
        totalReports: 127,
        pendingReports: 18,
        resolvedReports: 92,
        activeUsers: 43
      })
    } catch (error) {
      console.error('Error fetching stats:', error)
    }
  }

  const setMockData = () => {
    // Mock data for demonstration
    const mockReports: Report[] = [
      {
        id: '1',
        userId: 'user1',
        userName: 'John Doe',
        location: {
          latitude: 25.7617,
          longitude: -80.1918,
          address: 'Miami Beach, FL'
        },
        description: 'Found significant damage to mangrove roots possibly due to boat activity.',
        photoURL: 'https://via.placeholder.com/150',
        status: 'Pending',
        createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60) }
      },
      {
        id: '2',
        userId: 'user2',
        userName: 'Jane Smith',
        location: {
          latitude: 25.7825,
          longitude: -80.2994,
          address: 'Coral Gables, FL'
        },
        description: 'Observed illegal cutting of mangrove trees near residential development.',
        photoURL: 'https://via.placeholder.com/150',
        status: 'In Progress',
        createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 3) }
      },
      {
        id: '3',
        userId: 'user3',
        userName: 'Robert Johnson',
        location: {
          latitude: 25.8102,
          longitude: -80.1409,
          address: 'North Miami, FL'
        },
        description: 'Healthy mangrove growth with new seedlings establishing in restoration area.',
        photoURL: 'https://via.placeholder.com/150',
        status: 'Resolved',
        createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 24) }
      },
      {
        id: '4',
        userId: 'user4',
        userName: 'Maria Garcia',
        location: {
          latitude: 25.9479,
          longitude: -80.1373,
          address: 'Aventura, FL'
        },
        description: 'Pollution from nearby construction site affecting mangrove water quality.',
        photoURL: 'https://via.placeholder.com/150',
        status: 'Pending',
        createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 36) }
      },
      {
        id: '5',
        userId: 'user5',
        userName: 'David Wilson',
        location: {
          latitude: 25.8575,
          longitude: -80.1772,
          address: 'Miami Shores, FL'
        },
        description: 'Spotted invasive species competing with native mangroves.',
        photoURL: 'https://via.placeholder.com/150',
        status: 'In Progress',
        createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 48) }
      }
    ]
    
    setRecentReports(mockReports)
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'Pending':
        return <Clock className="w-5 h-5 text-yellow-500" />
      case 'In Progress':
        return <AlertCircle className="w-5 h-5 text-blue-500" />
      case 'Resolved':
        return <CheckCircle className="w-5 h-5 text-green-500" />
      default:
        return <Clock className="w-5 h-5 text-gray-500" />
    }
  }

  const getStatusClass = (status: string) => {
    switch (status) {
      case 'Pending':
        return 'bg-yellow-100 text-yellow-800'
      case 'In Progress':
        return 'bg-blue-100 text-blue-800'
      case 'Resolved':
        return 'bg-green-100 text-green-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  return (
    <div>
      <h1 className="text-2xl font-semibold text-gray-900">Dashboard</h1>
      
      {/* Stats Cards */}
      <div className="grid grid-cols-1 gap-5 mt-6 sm:grid-cols-2 lg:grid-cols-4">
        <div className="p-5 bg-white rounded-lg shadow">
          <div className="flex items-center">
            <div className="flex-shrink-0 p-3 bg-mangrove-100 rounded-md">
              <FileText className="w-6 h-6 text-mangrove-600" />
            </div>
            <div className="flex-1 w-0 ml-5">
              <dl>
                <dt className="text-sm font-medium text-gray-500 truncate">Total Reports</dt>
                <dd className="text-3xl font-semibold text-gray-900">{stats.totalReports}</dd>
              </dl>
            </div>
          </div>
        </div>
        
        <div className="p-5 bg-white rounded-lg shadow">
          <div className="flex items-center">
            <div className="flex-shrink-0 p-3 bg-yellow-100 rounded-md">
              <Clock className="w-6 h-6 text-yellow-600" />
            </div>
            <div className="flex-1 w-0 ml-5">
              <dl>
                <dt className="text-sm font-medium text-gray-500 truncate">Pending Reports</dt>
                <dd className="text-3xl font-semibold text-gray-900">{stats.pendingReports}</dd>
              </dl>
            </div>
          </div>
        </div>
        
        <div className="p-5 bg-white rounded-lg shadow">
          <div className="flex items-center">
            <div className="flex-shrink-0 p-3 bg-green-100 rounded-md">
              <CheckCircle className="w-6 h-6 text-green-600" />
            </div>
            <div className="flex-1 w-0 ml-5">
              <dl>
                <dt className="text-sm font-medium text-gray-500 truncate">Resolved Reports</dt>
                <dd className="text-3xl font-semibold text-gray-900">{stats.resolvedReports}</dd>
              </dl>
            </div>
          </div>
        </div>
        
        <div className="p-5 bg-white rounded-lg shadow">
          <div className="flex items-center">
            <div className="flex-shrink-0 p-3 bg-blue-100 rounded-md">
              <Users className="w-6 h-6 text-blue-600" />
            </div>
            <div className="flex-1 w-0 ml-5">
              <dl>
                <dt className="text-sm font-medium text-gray-500 truncate">Active Users</dt>
                <dd className="text-3xl font-semibold text-gray-900">{stats.activeUsers}</dd>
              </dl>
            </div>
          </div>
        </div>
      </div>
      
      {/* Recent Reports */}
      <div className="mt-8">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-medium text-gray-900">Recent Reports</h2>
          <Link 
            to="/reports" 
            className="text-sm font-medium text-mangrove-600 hover:text-mangrove-500"
          >
            View all
          </Link>
        </div>
        
        <div className="mt-4 overflow-hidden bg-white shadow sm:rounded-md">
          <ul className="divide-y divide-gray-200">
            {loading ? (
              <li className="px-6 py-4 text-center text-gray-500">Loading reports...</li>
            ) : recentReports.length === 0 ? (
              <li className="px-6 py-4 text-center text-gray-500">No reports found</li>
            ) : (
              recentReports.map((report) => (
                <li key={report.id}>
                  <div className="px-4 py-4 sm:px-6">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <p className="text-sm font-medium text-mangrove-600 truncate">
                          {report.userName}
                        </p>
                        <div className="ml-2 flex-shrink-0">
                          <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusClass(report.status)}`}>
                            {report.status}
                          </span>
                        </div>
                      </div>
                      <div className="flex items-center text-sm text-gray-500">
                        <p>
                          {formatDate(report.createdAt.toDate())}
                        </p>
                      </div>
                    </div>
                    <div className="mt-2 sm:flex sm:justify-between">
                      <div className="sm:flex">
                        <p className="flex items-center text-sm text-gray-500">
                          <MapPin className="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" />
                          {report.location.address || `${report.location.latitude.toFixed(4)}, ${report.location.longitude.toFixed(4)}`}
                        </p>
                      </div>
                      <div className="flex items-center mt-2 text-sm text-gray-500 sm:mt-0">
                        {getStatusIcon(report.status)}
                        <p className="ml-1">{report.status}</p>
                      </div>
                    </div>
                    <p className="mt-2 text-sm text-gray-600 line-clamp-2">{report.description}</p>
                  </div>
                </li>
              ))
            )}
          </ul>
        </div>
      </div>
    </div>
  )
}

export default DashboardHome

