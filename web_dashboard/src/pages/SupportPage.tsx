import { useState, useEffect, useRef } from 'react'
import { collection, query, orderBy, onSnapshot, addDoc, serverTimestamp, where } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { formatDate, getInitials } from '@/lib/utils'
import { Send, User, Search } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { useAuth } from '@/hooks/useAuth'
import { useToast } from '@/hooks/useToast'

interface ChatMessage {
  id: string
  text: string
  senderId: string
  senderName: string
  senderType: 'worker' | 'user'
  conversationId: string
  createdAt: any // Firestore timestamp
}

interface Conversation {
  id: string
  userId: string
  userName: string
  lastMessage: string
  lastMessageDate: any // Firestore timestamp
  unreadCount: number
}

const SupportPage = () => {
  const [conversations, setConversations] = useState<Conversation[]>([])
  const [filteredConversations, setFilteredConversations] = useState<Conversation[]>([])
  const [selectedConversation, setSelectedConversation] = useState<Conversation | null>(null)
  const [messages, setMessages] = useState<ChatMessage[]>([])
  const [newMessage, setNewMessage] = useState('')
  const [searchTerm, setSearchTerm] = useState('')
  const [loading, setLoading] = useState(true)
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const { user } = useAuth()
  const { toast } = useToast()

  // Fetch conversations
  useEffect(() => {
    // In a real app, fetch conversations from Firestore
    // For demo, use mock data
    setMockConversations()
    setLoading(false)
  }, [])

  // Filter conversations when search term changes
  useEffect(() => {
    if (searchTerm) {
      const filtered = conversations.filter(conversation => 
        conversation.userName.toLowerCase().includes(searchTerm.toLowerCase())
      )
      setFilteredConversations(filtered)
    } else {
      setFilteredConversations(conversations)
    }
  }, [conversations, searchTerm])

  // Fetch messages for selected conversation
  useEffect(() => {
    if (selectedConversation) {
      // In a real app, fetch messages from Firestore
      // For demo, use mock data
      setMockMessages(selectedConversation.id)
      
      // Mark conversation as read
      const updatedConversations = conversations.map(conv => 
        conv.id === selectedConversation.id ? { ...conv, unreadCount: 0 } : conv
      )
      setConversations(updatedConversations)
      setFilteredConversations(updatedConversations)
    }
  }, [selectedConversation])

  // Scroll to bottom when messages change
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const setMockConversations = () => {
    const mockConversations: Conversation[] = [
      {
        id: '1',
        userId: 'user1',
        userName: 'John Doe',
        lastMessage: 'When will someone check the reported issue?',
        lastMessageDate: { toDate: () => new Date(Date.now() - 1000 * 60 * 30) },
        unreadCount: 2
      },
      {
        id: '2',
        userId: 'user2',
        userName: 'Jane Smith',
        lastMessage: 'Thanks for your help with the mangrove restoration project!',
        lastMessageDate: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 3) },
        unreadCount: 0
      },
      {
        id: '3',
        userId: 'user3',
        userName: 'Robert Johnson',
        lastMessage: 'I have some questions about the reporting process.',
        lastMessageDate: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 24) },
        unreadCount: 1
      },
      {
        id: '4',
        userId: 'user4',
        userName: 'Maria Garcia',
        lastMessage: 'The pollution issue is getting worse. Can someone check it soon?',
        lastMessageDate: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 48) },
        unreadCount: 0
      },
      {
        id: '5',
        userId: 'user5',
        userName: 'David Wilson',
        lastMessage: 'Thanks for the quick response to my report!',
        lastMessageDate: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 72) },
        unreadCount: 0
      }
    ]
    
    setConversations(mockConversations)
    setFilteredConversations(mockConversations)
  }

  const setMockMessages = (conversationId: string) => {
    let mockMessages: ChatMessage[] = []
    
    switch (conversationId) {
      case '1':
        mockMessages = [
          {
            id: '1-1',
            text: 'Hello, I submitted a report about mangrove damage in Miami Beach yesterday.',
            senderId: 'user1',
            senderName: 'John Doe',
            senderType: 'user',
            conversationId: '1',
            createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 2) }
          },
          {
            id: '1-2',
            text: 'Hi John, thank you for your report. We have received it and are reviewing it.',
            senderId: 'worker1',
            senderName: 'Support Team',
            senderType: 'worker',
            conversationId: '1',
            createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 1.5) }
          },
          {
            id: '1-3',
            text: 'When will someone check the reported issue? It seems to be getting worse.',
            senderId: 'user1',
            senderName: 'John Doe',
            senderType: 'user',
            conversationId: '1',
            createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 30) }
          }
        ]
        break
      case '2':
        mockMessages = [
          {
            id: '2-1',
            text: 'I wanted to thank your team for organizing the mangrove restoration project last weekend.',
            senderId: 'user2',
            senderName: 'Jane Smith',
            senderType: 'user',
            conversationId: '2',
            createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 4) }
          },
          {
            id: '2-2',
            text: 'You\'re welcome, Jane! We\'re glad you participated. The project was a great success.',
            senderId: 'worker1',
            senderName: 'Support Team',
            senderType: 'worker',
            conversationId: '2',
            createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 3.5) }
          },
          {
            id: '2-3',
            text: 'Thanks for your help with the mangrove restoration project!',
            senderId: 'user2',
            senderName: 'Jane Smith',
            senderType: 'user',
            conversationId: '2',
            createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 3) }
          }
        ]
        break
      case '3':
        mockMessages = [
          {
            id: '3-1',
            text: 'Hello, I have some questions about the reporting process.',
            senderId: 'user3',
            senderName: 'Robert Johnson',
            senderType: 'user',
            conversationId: '3',
            createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 24) }
          }
        ]
        break
      case '4':
        mockMessages = [
          {
            id: '4-1',
            text: 'I\'ve noticed increased pollution near the mangroves in Aventura.',
            senderId: 'user4',
            senderName: 'Maria Garcia',
            senderType: 'user',
            conversationId: '4',
            createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 50) }
          },
          {
            id: '4-2',
            text: 'Thank you for reporting this, Maria. We\'ve assigned a team to investigate.',
            senderId: 'worker1',
            senderName: 'Support Team',
            senderType: 'worker',
            conversationId: '4',
            createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 49) }
          },
          {
            id: '4-3',
            text: 'The pollution issue is getting worse. Can someone check it soon?',
            senderId: 'user4',
            senderName: 'Maria Garcia',
            senderType: 'user',
            conversationId: '4',
            createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 48) }
          }
        ]
        break
      case '5':
        mockMessages = [
          {
            id: '5-1',
            text: 'I submitted a report about invasive species in Miami Shores.',
            senderId: 'user5',
            senderName: 'David Wilson',
            senderType: 'user',
            conversationId: '5',
            createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 74) }
          },
          {
            id: '5-2',
            text: 'We\'ve received your report, David. A conservation specialist will assess the situation tomorrow.',
            senderId: 'worker1',
            senderName: 'Support Team',
            senderType: 'worker',
            conversationId: '5',
            createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 73) }
          },
          {
            id: '5-3',
            text: 'Thanks for the quick response to my report!',
            senderId: 'user5',
            senderName: 'David Wilson',
            senderType: 'user',
            conversationId: '5',
            createdAt: { toDate: () => new Date(Date.now() - 1000 * 60 * 60 * 72) }
          }
        ]
        break
      default:
        break
    }
    
    setMessages(mockMessages)
  }

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!newMessage.trim() || !selectedConversation || !user) return
    
    try {
      // In a real app, add message to Firestore
      // const messagesRef = collection(db, 'messages')
      // await addDoc(messagesRef, {
      //   text: newMessage,
      //   senderId: user.uid,
      //   senderName: user.displayName || user.email?.split('@')[0] || 'Support Team',
      //   senderType: 'worker',
      //   conversationId: selectedConversation.id,
      //   createdAt: serverTimestamp()
      // })
      
      // For demo, add message to local state
      const newMsg: ChatMessage = {
        id: `${selectedConversation.id}-${messages.length + 1}`,
        text: newMessage,
        senderId: user.uid,
        senderName: user.displayName || user.email?.split('@')[0] || 'Support Team',
        senderType: 'worker',
        conversationId: selectedConversation.id,
        createdAt: { toDate: () => new Date() }
      }
      
      setMessages([...messages, newMsg])
      
      // Update conversation last message
      const updatedConversations = conversations.map(conv => 
        conv.id === selectedConversation.id 
          ? { 
              ...conv, 
              lastMessage: newMessage,
              lastMessageDate: { toDate: () => new Date() }
            } 
          : conv
      )
      setConversations(updatedConversations)
      setFilteredConversations(updatedConversations)
      
      // Clear input
      setNewMessage('')
    } catch (error) {
      console.error('Error sending message:', error)
      toast({
        title: 'Error',
        description: 'Failed to send message. Please try again.',
        variant: 'destructive',
      })
    }
  }

  return (
    <div>
      <h1 className="text-2xl font-semibold text-gray-900">Support Chat</h1>
      
      <div className="grid grid-cols-1 gap-6 mt-6 lg:grid-cols-3">
        {/* Conversations List */}
        <div className="bg-white rounded-lg shadow lg:col-span-1">
          <div className="px-4 py-5 border-b sm:px-6">
            <div className="relative">
              <div className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                <Search className="w-5 h-5 text-gray-400" />
              </div>
              <Input
                type="text"
                placeholder="Search users..."
                className="pl-10"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
          
          <div className="overflow-y-auto" style={{ maxHeight: '500px' }}>
            <ul className="divide-y divide-gray-200">
              {loading ? (
                <li className="px-6 py-4 text-center text-gray-500">Loading conversations...</li>
              ) : filteredConversations.length === 0 ? (
                <li className="px-6 py-4 text-center text-gray-500">No conversations found</li>
              ) : (
                filteredConversations.map((conversation) => (
                  <li 
                    key={conversation.id} 
                    className={`px-4 py-4 cursor-pointer hover:bg-gray-50 ${
                      selectedConversation?.id === conversation.id ? 'bg-gray-50' : ''
                    }`}
                    onClick={() => setSelectedConversation(conversation)}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <div className="w-10 h-10 bg-mangrove-100 text-mangrove-700 rounded-full flex items-center justify-center">
                          {getInitials(conversation.userName)}
                        </div>
                        <div className="ml-3">
                          <p className="text-sm font-medium text-gray-900">{conversation.userName}</p>
                          <p className="text-sm text-gray-500 truncate" style={{ maxWidth: '200px' }}>
                            {conversation.lastMessage}
                          </p>
                        </div>
                      </div>
                      <div className="flex flex-col items-end">
                        <p className="text-xs text-gray-500">
                          {formatDate(conversation.lastMessageDate.toDate())}
                        </p>
                        {conversation.unreadCount > 0 && (
                          <span className="px-2 py-1 mt-1 text-xs font-semibold text-white bg-mangrove-500 rounded-full">
                            {conversation.unreadCount}
                          </span>
                        )}
                      </div>
                    </div>
                  </li>
                ))
              )}
            </ul>
          </div>
        </div>
        
        {/* Chat Area */}
        <div className="flex flex-col bg-white rounded-lg shadow lg:col-span-2">
          {selectedConversation ? (
            <>
              {/* Chat Header */}
              <div className="px-4 py-4 border-b sm:px-6">
                <div className="flex items-center">
                  <div className="w-10 h-10 bg-mangrove-100 text-mangrove-700 rounded-full flex items-center justify-center">
                    {getInitials(selectedConversation.userName)}
                  </div>
                  <div className="ml-3">
                    <p className="text-sm font-medium text-gray-900">{selectedConversation.userName}</p>
                    <p className="text-xs text-gray-500">User ID: {selectedConversation.userId}</p>
                  </div>
                </div>
              </div>
              
              {/* Messages */}
              <div className="flex-1 p-4 overflow-y-auto" style={{ maxHeight: '400px' }}>
                <div className="space-y-4">
                  {messages.map((message) => (
                    <div 
                      key={message.id} 
                      className={`flex ${message.senderType === 'worker' ? 'justify-end' : 'justify-start'}`}
                    >
                      <div 
                        className={`max-w-xs px-4 py-2 rounded-lg ${
                          message.senderType === 'worker' 
                            ? 'bg-mangrove-500 text-white' 
                            : 'bg-gray-100 text-gray-800'
                        }`}
                      >
                        <p className="text-sm">{message.text}</p>
                        <p className="mt-1 text-xs text-right opacity-70">
                          {formatDate(message.createdAt.toDate())}
                        </p>
                      </div>
                    </div>
                  ))}
                  <div ref={messagesEndRef} />
                </div>
              </div>
              
              {/* Message Input */}
              <div className="px-4 py-4 border-t">
                <form onSubmit={handleSendMessage} className="flex">
                  <Input
                    type="text"
                    placeholder="Type a message..."
                    value={newMessage}
                    onChange={(e) => setNewMessage(e.target.value)}
                    className="flex-1"
                  />
                  <Button type="submit" className="ml-2">
                    <Send className="w-4 h-4" />
                  </Button>
                </form>
              </div>
            </>
          ) : (
            <div className="flex flex-col items-center justify-center h-full p-6 text-gray-500">
              <User className="w-16 h-16 mb-4 text-gray-300" />
              <p className="text-lg font-medium">Select a conversation</p>
              <p className="mt-1 text-sm text-center">
                Choose a conversation from the list to start chatting with users.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default SupportPage

