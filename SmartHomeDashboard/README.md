# Smart Home Dashboard

A modern, real-time Smart Home Dashboard built with Next.js and Firebase. This admin dashboard allows you to monitor and control all your smart home devices in real-time with a beautiful, responsive interface.

## Features

- 🏠 **Real-time Monitoring**: Live updates from Firebase Realtime Database
- 🎛️ **Device Control**: Toggle devices on/off directly from the dashboard
- 📊 **Statistics**: Comprehensive stats about devices, rooms, and users
- 🏢 **Multi-Environment**: Switch between different smart home environments
- 📱 **Responsive Design**: Works perfectly on desktop, tablet, and mobile
- 🎨 **Modern UI**: Glass morphism design with smooth animations
- ⚡ **Fast Performance**: Built with Next.js for optimal performance

## Technologies Used

- **Next.js 14** - React framework for production
- **Firebase** - Real-time database and hosting
- **Tailwind CSS** - Utility-first CSS framework
- **Framer Motion** - Animation library
- **Lucide React** - Beautiful icons

## Getting Started

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Run the development server:**
   ```bash
   npm run dev
   ```

3. **Open your browser:**
   Navigate to [http://localhost:3000](http://localhost:3000)

## Project Structure

```
src/
├── components/          # Reusable UI components
│   ├── DeviceCard.js   # Individual device control card
│   ├── RoomCard.js     # Room overview with devices
│   ├── StatsCard.js    # Statistics display card
│   └── EnvironmentSelector.js # Environment switcher
├── hooks/              # Custom React hooks
│   └── useFirebaseData.js # Firebase real-time data hook
├── lib/                # Utility libraries
│   └── firebase.js     # Firebase configuration
├── pages/              # Next.js pages
│   ├── _app.js        # App component
│   └── index.js       # Main dashboard page
└── styles/             # Global styles
    └── globals.css     # Tailwind and custom CSS
```

## Features Overview

### Real-time Device Control
- View all devices across different rooms
- Toggle devices on/off with smooth animations
- Visual indicators for device states
- Symbol assignment tracking

### Environment Management
- Switch between different smart home environments
- Environment-specific statistics
- User and admin information display

### Comprehensive Statistics
- Total and active device counts
- Room usage statistics
- User management overview
- System status monitoring

### Responsive Design
- Mobile-first approach
- Glass morphism UI design
- Smooth animations and transitions
- Dark theme optimized for smart home monitoring

## Firebase Structure

The dashboard expects a Firebase Realtime Database with the following structure:

```json
{
  "environments": {
    "env_id": {
      "name": "Environment Name",
      "adminId": "user_id",
      "devices": { ... },
      "rooms": { ... },
      "users": { ... }
    }
  },
  "symbols": { ... },
  "users": { ... }
}
```

## Building for Production

```bash
npm run build
npm start
```

## License

This project is for demonstration purposes. Please ensure you have proper permissions to use the Firebase configuration provided.
