import { Link } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Home } from 'lucide-react'

const NotFoundPage = () => {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen px-4 py-12 bg-gray-50 sm:px-6 lg:px-8">
      <div className="w-full max-w-md space-y-8 text-center">
        <div>
          <h1 className="text-6xl font-extrabold text-mangrove-500">404</h1>
          <h2 className="mt-6 text-3xl font-bold text-gray-900">Page Not Found</h2>
          <p className="mt-2 text-sm text-gray-600">
            The page you are looking for doesn't exist or has been moved.
          </p>
        </div>
        <div className="mt-8">
          <Link to="/">
            <Button className="w-full">
              <Home className="w-4 h-4 mr-2" />
              Back to Dashboard
            </Button>
          </Link>
        </div>
      </div>
    </div>
  )
}

export default NotFoundPage

