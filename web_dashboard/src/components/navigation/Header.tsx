import { useAuth } from '@/hooks/useAuth'
import { Menu, Bell } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { getInitials } from '@/lib/utils'

interface HeaderProps {
  sidebarOpen: boolean
  setSidebarOpen: (open: boolean) => void
}

const Header = ({ sidebarOpen, setSidebarOpen }: HeaderProps) => {
  const { user } = useAuth()
  
  return (
    <header className="sticky top-0 z-10 flex items-center justify-between h-16 px-4 bg-white border-b border-gray-200 sm:px-6">
      <div className="flex items-center">
        <button
          type="button"
          className="p-1 text-gray-500 rounded-md lg:hidden hover:bg-gray-100 focus:outline-none"
          onClick={() => setSidebarOpen(!sidebarOpen)}
        >
          <Menu className="w-6 h-6" />
        </button>
        <h1 className="ml-3 text-xl font-semibold text-gray-900 lg:ml-0">Mangrove Conservation Dashboard</h1>
      </div>
      
      <div className="flex items-center space-x-4">
        {/* Notifications */}
        <Button variant="ghost" size="icon" className="relative">
          <Bell className="w-5 h-5" />
          <span className="absolute top-0 right-0 w-2 h-2 bg-red-500 rounded-full"></span>
        </Button>
        
        {/* User profile */}
        <div className="flex items-center">
          <div className="w-8 h-8 bg-mangrove-100 text-mangrove-700 rounded-full flex items-center justify-center">
            {user?.displayName ? getInitials(user.displayName) : 'U'}
          </div>
          <span className="ml-2 text-sm font-medium text-gray-700 hidden sm:inline-block">
            {user?.displayName || user?.email?.split('@')[0] || 'User'}
          </span>
        </div>
      </div>
    </header>
  )
}

export default Header

