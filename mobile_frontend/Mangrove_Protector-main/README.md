# Mangrove Protector - Individual Focused App

A Flutter mobile application for anonymous reporting of illegal activities affecting mangroves, with end-to-end encryption and privacy protection.

## Features

### 🔐 Privacy & Security
- **End-to-End Encryption**: All data encrypted using libsodium
- **Anonymous Reporting**: No personal information collected
- **Local Key Storage**: Private keys stored securely on device
- **Supabase Authentication**: Secure email-based authentication

### 📱 Core Functionality
- **Report Incidents**: Capture photos and report illegal activities
- **AI Analysis**: Automatic analysis of reported images (placeholder)
- **Status Tracking**: Monitor report progress and updates
- **Rewards System**: Earn credits for verified reports
- **Anonymous Rewards**: Claim rewards using QR codes

### 🎯 User Experience
- **Bottom Navigation**: Easy access to main features
- **Real-time Location**: GPS tracking for accurate reporting
- **Anti-spoof Protection**: Live photo capture only
- **Offline Support**: Basic offline functionality

## App Structure

### Authentication & Onboarding
- **Splash Screen**: App loading and auth state check
- **Login/Signup**: Email-based authentication with Supabase
- **Key Generation**: Automatic encryption key setup

### Main Navigation (Bottom Tabs)
1. **Report**: Capture new incident reports
2. **Feed**: View past reports and status updates
3. **Rewards**: Credits, milestones, and reward claiming
4. **Profile**: Settings, keys, privacy, and support

### Report Flow
1. **Capture Screen**: Take photos with location tracking
2. **Review Screen**: Add details and submit report
3. **AI Analysis**: Automatic image analysis (placeholder)
4. **Status Updates**: Track report progress

## Technical Architecture

### Dependencies
- **Supabase**: Authentication and database
- **libsodium**: End-to-end encryption
- **Google Maps**: Location services and mapping
- **Image Picker**: Camera functionality
- **Provider**: State management

### Key Components
- **EncryptionService**: Handles libsodium operations
- **SupabaseService**: Database operations (with placeholders)
- **AuthProvider**: Authentication state management
- **IllegalActivityProvider**: Report management

### Data Models
- **User**: Anonymous user with encryption keys
- **IllegalActivity**: Report data with AI analysis
- **Reward**: Credit and milestone tracking

## Setup Instructions

### Prerequisites
- Flutter SDK 3.8.1+
- Supabase project
- Google Maps API key

### Configuration
1. Update Supabase credentials in `main.dart`
2. Add Google Maps API key for location services
3. Configure Firebase for push notifications (optional)

### Database Schema (Supabase)
```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY,
  public_key TEXT,
  has_backed_up_private_key BOOLEAN DEFAULT FALSE,
  points INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Illegal activities table
CREATE TABLE illegal_activities (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  activity_type TEXT NOT NULL,
  description TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  image_url TEXT,
  status TEXT DEFAULT 'pending',
  ai_score DOUBLE PRECISION,
  ai_explanation TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  verified_by TEXT,
  verified_at TIMESTAMP,
  admin_notes TEXT,
  resolution_notes TEXT,
  reported_date TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

## Privacy Features

### Data Protection
- **Encryption**: All sensitive data encrypted with libsodium
- **Anonymity**: No personal information stored
- **Local Storage**: Private keys never leave device
- **Data Retention**: Automatic cleanup after 30 days

### User Rights
- Request data deletion
- Export encrypted data
- Opt out of data collection
- Contact privacy team

## Development Status

### ✅ Completed
- Individual user model (no communities)
- Supabase authentication integration
- Encryption service with libsodium
- Main navigation structure
- Report capture and review flow
- Privacy-focused UI components

### 🔄 In Progress
- Supabase database implementation
- AI analysis integration
- Push notification setup
- Offline functionality

### 📋 TODO
- Complete Supabase service implementation
- Add AI image analysis
- Implement reward system backend
- Add admin dashboard
- Performance optimization

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with privacy in mind
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For privacy concerns: privacy@mangroveprotector.com
For technical support: support@mangroveprotector.com