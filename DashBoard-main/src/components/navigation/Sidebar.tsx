import { NavLink } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'
import { 
  LayoutDashboard, 
  FileText, 
  Bell, 
  MessageSquare, 
  LogOut, 
  X 
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'

interface SidebarProps {
  open: boolean
  setOpen: (open: boolean) => void
}

const Sidebar = ({ open, setOpen }: SidebarProps) => {
  const { signOut } = useAuth()

  const handleSignOut = async () => {
    try {
      await signOut()
    } catch (error) {
      console.error('Error signing out:', error)
    }
  }

  return (
    <>
      {/* Mobile sidebar backdrop */}
      {open && (
        <div 
          className="fixed inset-0 z-40 bg-black/50 lg:hidden" 
          onClick={() => setOpen(false)}
        />
      )}

      {/* Sidebar */}
      <div 
        className={cn(
          "fixed inset-y-0 left-0 z-50 w-64 bg-white shadow-lg transform transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:inset-0",
          open ? "translate-x-0" : "-translate-x-full"
        )}
      >
        <div className="flex flex-col h-full">
          {/* Sidebar header */}
          <div className="flex items-center justify-between px-4 py-5 border-b">
            <div className="flex items-center space-x-2">
              <div className="w-8 h-8 bg-mangrove-500 rounded-md flex items-center justify-center">
                <span className="text-white font-bold">M</span>
              </div>
              <span className="text-xl font-semibold text-gray-900">Mangrove</span>
            </div>
            <button 
              className="p-1 text-gray-500 rounded-md lg:hidden hover:bg-gray-100"
              onClick={() => setOpen(false)}
            >
              <X size={20} />
            </button>
          </div>

          {/* Navigation links */}
          <nav className="flex-1 px-2 py-4 space-y-1 overflow-y-auto">
            <NavLink 
              to="/" 
              end
              className={({ isActive }) => cn(
                "flex items-center px-3 py-2 text-sm font-medium rounded-md group",
                isActive 
                  ? "bg-mangrove-50 text-mangrove-700" 
                  : "text-gray-700 hover:bg-mangrove-50 hover:text-mangrove-700"
              )}
            >
              <LayoutDashboard className="w-5 h-5 mr-3 text-mangrove-500" />
              Dashboard
            </NavLink>

            <NavLink 
              to="/reports" 
              className={({ isActive }) => cn(
                "flex items-center px-3 py-2 text-sm font-medium rounded-md group",
                isActive 
                  ? "bg-mangrove-50 text-mangrove-700" 
                  : "text-gray-700 hover:bg-mangrove-50 hover:text-mangrove-700"
              )}
            >
              <FileText className="w-5 h-5 mr-3 text-mangrove-500" />
              Reports
            </NavLink>

            <NavLink 
              to="/notifications" 
              className={({ isActive }) => cn(
                "flex items-center px-3 py-2 text-sm font-medium rounded-md group",
                isActive 
                  ? "bg-mangrove-50 text-mangrove-700" 
                  : "text-gray-700 hover:bg-mangrove-50 hover:text-mangrove-700"
              )}
            >
              <Bell className="w-5 h-5 mr-3 text-mangrove-500" />
              Notifications
            </NavLink>

            <NavLink 
              to="/support" 
              className={({ isActive }) => cn(
                "flex items-center px-3 py-2 text-sm font-medium rounded-md group",
                isActive 
                  ? "bg-mangrove-50 text-mangrove-700" 
                  : "text-gray-700 hover:bg-mangrove-50 hover:text-mangrove-700"
              )}
            >
              <MessageSquare className="w-5 h-5 mr-3 text-mangrove-500" />
              Support
            </NavLink>
          </nav>

          {/* Sidebar footer */}
          <div className="p-4 border-t">
            <Button 
              variant="outline" 
              className="w-full justify-start text-gray-700 hover:text-red-600"
              onClick={handleSignOut}
            >
              <LogOut className="w-5 h-5 mr-3" />
              Sign out
            </Button>
          </div>
        </div>
      </div>
    </>
  )
}

export default Sidebar

