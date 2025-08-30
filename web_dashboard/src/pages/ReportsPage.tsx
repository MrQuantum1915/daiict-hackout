import { useState, useEffect } from 'react'
import { collection, query, orderBy, onSnapshot, doc, updateDoc } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { formatDate } from '@/lib/utils'
import { MapPin, CheckCircle, AlertCircle, Clock, Search, Filter } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { useToast } from '@/hooks/useToast'
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'
import L from 'leaflet'

// Fix Leaflet marker icon issue
delete (L.Icon.Default.prototype as any)._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-shadow.png',
})

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

const ReportsPage = () => {
  const [reports, setReports] = useState<Report[]>([])
  const [filteredReports, setFilteredReports] = useState<Report[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState<string>('All')
  const [selectedReport, setSelectedReport] = useState<Report | null>(null)
  const [mapCenter, setMapCenter] = useState<[number, number]>([25.7617, -80.1918]) // Default to Miami
  const { toast } = useToast()

  useEffect(() => {
    // Subscribe to reports
    const reportsRef = collection(db, 'reports')
    const reportsQuery = query(
      reportsRef,
      orderBy('createdAt', 'desc')
    )

    const unsubscribe = onSnapshot(reportsQuery, (snapshot) => {
      const fetchedReports: Report[] = []
      snapshot.forEach((doc) => {
        fetchedReports.push({ id: doc.id, ...doc.data() } as Report)
      })
      setReports(fetchedReports)
      setFilteredReports(fetchedReports)
      setLoading(false)
    }, (error) => {
      console.error('Error fetching reports:', error)
      setLoading(false)
      
      // For demo purposes, set mock data if there's an error
      setMockData()
    })

    return () => unsubscribe()
  }, [])

  useEffect(() => {
    // Apply filters when reports, searchTerm, or statusFilter changes
    let filtered = reports

    // Apply search filter
    if (searchTerm) {
      const term = searchTerm.toLowerCase()
      filtered = filtered.filter(
        report => 
          report.userName.toLowerCase().includes(term) ||
          report.description.toLowerCase().includes(term) ||
          (report.location.address && report.location.address.toLowerCase().includes(term))
      )
    }

    // Apply status filter
    if (statusFilter !== 'All') {
      filtered = filtered.filter(report => report.status === statusFilter)
    }

    setFilteredReports(filtered)
  }, [reports, searchTerm, statusFilter])

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
      },
      {
        id: '6',
        userId: 'user6',
        userName: 'Sarah Johnson',
        location: {
          latitude: 25.8697,
          longitude: -80.1646,
          address: 'North Bay Village, FL'
        },
        description: 'Community cleanup event removed 50+ pounds of trash from mangrove area.',
        photoURL: 'https://via.placeholder.com/150',
        status: 'Resolved',
        createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 72) }
      },
      {
        id: '7',
        userId: 'user7',
        userName: 'Michael Brown',
        location: {
          latitude: 25.8032,
          longitude: -80.1219,
          address: 'Miami Beach, FL'
        },
        description: 'Educational tour group observed damaging mangrove branches for souvenirs.',
        photoURL: 'https://via.placeholder.com/150',
        status: 'In Progress',
        createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 96) }
      }
    ]
    
    setReports(mockReports)
    setFilteredReports(mockReports)
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

  const handleStatusChange = async (reportId: string, newStatus: 'Pending' | 'In Progress' | 'Resolved') => {
    try {
      // In a real app, update the status in Firestore
      // const reportRef = doc(db, 'reports', reportId)
      // await updateDoc(reportRef, { status: newStatus })
      
      // For demo, update the local state
      const updatedReports = reports.map(report => 
        report.id === reportId ? { ...report, status: newStatus } : report
      )
      setReports(updatedReports)
      
      toast({
        title: 'Status Updated',
        description: `Report status changed to ${newStatus}`,
      })
    } catch (error) {
      console.error('Error updating report status:', error)
      toast({
        title: 'Update Failed',
        description: 'Failed to update report status. Please try again.',
        variant: 'destructive',
      })
    }
  }

  const handleReportClick = (report: Report) => {
    setSelectedReport(report)
    setMapCenter([report.location.latitude, report.location.longitude])
  }

  return (
    <div>
      <h1 className="text-2xl font-semibold text-gray-900">Reports</h1>
      
      {/* Filters */}
      <div className="flex flex-col gap-4 mt-6 md:flex-row">
        <div className="relative flex-1">
          <div className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
            <Search className="w-5 h-5 text-gray-400" />
          </div>
          <Input
            type="text"
            placeholder="Search reports..."
            className="pl-10"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        
        <div className="flex items-center space-x-2">
          <Filter className="w-5 h-5 text-gray-400" />
          <div className="flex space-x-1">
            <Button
              variant={statusFilter === 'All' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setStatusFilter('All')}
            >
              All
            </Button>
            <Button
              variant={statusFilter === 'Pending' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setStatusFilter('Pending')}
              className={statusFilter === 'Pending' ? '' : 'text-yellow-600'}
            >
              Pending
            </Button>
            <Button
              variant={statusFilter === 'In Progress' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setStatusFilter('In Progress')}
              className={statusFilter === 'In Progress' ? '' : 'text-blue-600'}
            >
              In Progress
            </Button>
            <Button
              variant={statusFilter === 'Resolved' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setStatusFilter('Resolved')}
              className={statusFilter === 'Resolved' ? '' : 'text-green-600'}
            >
              Resolved
            </Button>
          </div>
        </div>
      </div>
      
      {/* Reports List and Map View */}
      <div className="grid grid-cols-1 gap-6 mt-6 lg:grid-cols-2">
        {/* Reports List */}
        <div className="overflow-hidden bg-white rounded-lg shadow">
          <div className="px-4 py-5 sm:px-6">
            <h2 className="text-lg font-medium text-gray-900">
              {filteredReports.length} {filteredReports.length === 1 ? 'Report' : 'Reports'}
            </h2>
          </div>
          
          <div className="max-h-[600px] overflow-y-auto">
            <ul className="divide-y divide-gray-200">
              {loading ? (
                <li className="px-6 py-4 text-center text-gray-500">Loading reports...</li>
              ) : filteredReports.length === 0 ? (
                <li className="px-6 py-4 text-center text-gray-500">No reports found</li>
              ) : (
                filteredReports.map((report) => (
                  <li 
                    key={report.id} 
                    className={`px-4 py-4 cursor-pointer hover:bg-gray-50 ${selectedReport?.id === report.id ? 'bg-gray-50' : ''}`}
                    onClick={() => handleReportClick(report)}
                  >
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
                    </div>
                    <p className="mt-2 text-sm text-gray-600 line-clamp-2">{report.description}</p>
                  </li>
                ))
              )}
            </ul>
          </div>
        </div>
        
        {/* Map and Details View */}
        <div className="flex flex-col h-[600px] bg-white rounded-lg shadow">
          {/* Map */}
          <div className="h-1/2 rounded-t-lg overflow-hidden">
            <MapContainer 
              center={mapCenter} 
              zoom={13} 
              style={{ height: '100%', width: '100%' }}
            >
              <TileLayer
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              />
              {filteredReports.map((report) => (
                <Marker 
                  key={report.id}
                  position={[report.location.latitude, report.location.longitude]}
                  eventHandlers={{
                    click: () => {
                      setSelectedReport(report)
                    },
                  }}
                >
                  <Popup>
                    <div>
                      <h3 className="font-medium">{report.userName}</h3>
                      <p className="text-sm">{report.description.substring(0, 50)}...</p>
                    </div>
                  </Popup>
                </Marker>
              ))}
            </MapContainer>
          </div>
          
          {/* Details */}
          <div className="flex-1 p-4 overflow-y-auto">
            {selectedReport ? (
              <div>
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-medium text-gray-900">Report Details</h3>
                  <span className={`px-2 py-1 text-xs font-semibold rounded-full ${getStatusClass(selectedReport.status)}`}>
                    {selectedReport.status}
                  </span>
                </div>
                
                <div className="mt-4 space-y-4">
                  <div>
                    <h4 className="text-sm font-medium text-gray-500">Reported by</h4>
                    <p className="mt-1 text-sm text-gray-900">{selectedReport.userName}</p>
                  </div>
                  
                  <div>
                    <h4 className="text-sm font-medium text-gray-500">Location</h4>
                    <p className="mt-1 text-sm text-gray-900">
                      {selectedReport.location.address || `${selectedReport.location.latitude.toFixed(6)}, ${selectedReport.location.longitude.toFixed(6)}`}
                    </p>
                  </div>
                  
                  <div>
                    <h4 className="text-sm font-medium text-gray-500">Date</h4>
                    <p className="mt-1 text-sm text-gray-900">
                      {formatDate(selectedReport.createdAt.toDate())}
                    </p>
                  </div>
                  
                  <div>
                    <h4 className="text-sm font-medium text-gray-500">Description</h4>
                    <p className="mt-1 text-sm text-gray-900">{selectedReport.description}</p>
                  </div>
                  
                  {selectedReport.photoURL && (
                    <div>
                      <h4 className="text-sm font-medium text-gray-500">Photo</h4>
                      <img 
                        src={selectedReport.photoURL} 
                        alt="Report" 
                        className="mt-1 object-cover rounded-md h-32 w-full"
                      />
                    </div>
                  )}
                  
                  <div>
                    <h4 className="text-sm font-medium text-gray-500">Status</h4>
                    <div className="flex mt-1 space-x-2">
                      <Button
                        size="sm"
                        variant={selectedReport.status === 'Pending' ? 'default' : 'outline'}
                        onClick={() => handleStatusChange(selectedReport.id, 'Pending')}
                        className={selectedReport.status === 'Pending' ? '' : 'text-yellow-600'}
                      >
                        Pending
                      </Button>
                      <Button
                        size="sm"
                        variant={selectedReport.status === 'In Progress' ? 'default' : 'outline'}
                        onClick={() => handleStatusChange(selectedReport.id, 'In Progress')}
                        className={selectedReport.status === 'In Progress' ? '' : 'text-blue-600'}
                      >
                        In Progress
                      </Button>
                      <Button
                        size="sm"
                        variant={selectedReport.status === 'Resolved' ? 'default' : 'outline'}
                        onClick={() => handleStatusChange(selectedReport.id, 'Resolved')}
                        className={selectedReport.status === 'Resolved' ? '' : 'text-green-600'}
                      >
                        Resolved
                      </Button>
                    </div>
                  </div>
                </div>
              </div>
            ) : (
              <div className="flex flex-col items-center justify-center h-full text-gray-500">
                <MapPin className="w-12 h-12 mb-2 text-gray-300" />
                <p>Select a report to view details</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export default ReportsPage

