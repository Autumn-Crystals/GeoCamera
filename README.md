# NGO Tree Plantation Tracking System

A comprehensive mobile application for NGOs to track tree plantations with geolocation, health monitoring, photo documentation, and offline support. Built with Flutter for cross-platform deployment.

## 🌟 Overview

This system empowers NGO field workers to efficiently monitor tree plantations through an intuitive mobile interface. The app combines geolocation tracking, camera integration, and intelligent health monitoring to provide real-time insights into plantation progress and tree health status.

## ✨ Key Features

### Core Functionality
- **Geolocation Tracking**: GPS-stamped tree plantation records with accurate coordinates
- **Photo Documentation**: Automated image stamping with location, date, and metadata
- **Offline-First Architecture**: Full functionality without internet connectivity with automatic sync
- **Health Monitoring**: Automated tree health calculations based on update frequency and condition reports
- **QR Code System**: Quick tree identification and access via generated QR codes

### Advanced Map Visualization
- **Interactive Map Display**: Custom circular markers color-coded by tree health status
- **Smart Clustering**: Dynamic grouping of nearby trees for improved performance with large datasets
- **Health-Based Filtering**: Filter trees by status (Healthy, Needs Attention, Critical, New)
- **Real-Time Legend**: Live statistics showing tree distribution by health category
- **Performance Optimized**: Smooth 60 FPS interactions even with 500+ trees

### Data Management
- **SQLite Database**: Local data persistence with schema versioning
- **Multi-Format Export**: CSV, Excel, and PDF report generation
- **Backup & Restore**: Complete data backup with JSON export
- **Role-Based Access**: Admin and worker roles with appropriate permissions
- **Search & Filters**: Advanced filtering by time period, area, and health status

### Field Worker Tools
- **Update Tracking**: Log tree growth measurements and condition changes
- **Route Planning**: Optimize field visit routes on interactive map
- **Calendar View**: Timeline visualization of plantation activities
- **Photo Gallery**: Organized view of all plantation photos with metadata
- **Weather Integration**: Current weather conditions for field planning

### Donor Engagement
- **Certificate Generation**: Automated PDF certificates for donors
- **Donor Portal**: Dedicated interface for donor tree information
- **Shareable Reports**: Export and share plantation data with stakeholders
- **Impact Analytics**: Visual dashboard showing environmental impact

## 🏗️ Technical Architecture

### Technology Stack
- **Framework**: Flutter 3.10.4+ (Dart SDK)
- **Database**: SQLite with sqflite package
- **Maps**: Google Maps Flutter with custom marker generation
- **State Management**: Provider pattern with ChangeNotifier
- **Local Storage**: SharedPreferences for user sessions
- **Networking**: Connectivity monitoring with auto-sync

### Project Structure
```
lib/
├── models/          # Data models (TreeRecord, TreeUpdate, MapModels)
├── screens/         # UI screens (14 screens total)
├── services/        # Business logic and utilities (20+ services)
├── widgets/         # Reusable UI components
└── theme/           # Consistent app theming
```

### Key Services
- **DatabaseService**: SQLite operations with migration support
- **HealthCalculator**: Automated health status determination
- **MarkerGenerator**: Custom map marker creation with caching
- **ClusteringService**: Efficient tree clustering algorithm
- **SyncService**: Offline data synchronization
- **ExportService**: Multi-format data export capabilities
- **LocationService**: GPS tracking and geocoding
- **NotificationService**: Local notifications for reminders

## 📊 Health Monitoring Algorithm

The system automatically calculates tree health based on:
- **New Plantation** (Gray): No updates recorded
- **Healthy** (Green): Good condition, updated within 30 days
- **Needs Attention** (Yellow): Good condition but 30-60 days old, or Moderate condition
- **Critical** (Red): Poor condition or 60+ days without update

## 🚀 Getting Started

### Prerequisites
```bash
Flutter SDK: ^3.10.4
Dart SDK: ^3.10.4
Android Studio / VS Code
Android SDK / Xcode (for iOS)
```

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/ngo-tree-tracker.git
cd ngo-tree-tracker
```

2. Install dependencies:
```bash
flutter pub get
```

3. Add your Google Maps API key:
   - Android: `android/app/src/main/AndroidManifest.xml`
   - iOS: `ios/Runner/AppDelegate.swift`

4. Run the app:
```bash
flutter run
```

### Building for Release

**Android APK:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## 📱 Screenshots & Features

### Dashboard
- Real-time statistics (Total trees, Updates, Today's entries)
- Quick action buttons for adding/updating trees
- Health analytics with visual charts
- Interactive map with health-coded markers
- Recent plantation list

### Map Visualization
- Color-coded circular markers indicating tree health
- Zoom-based clustering for performance
- Tap markers to view tree details
- Collapsible legend with live counts
- Smooth animations and transitions

### Tree Management
- Detailed tree profiles with photo timeline
- Update history with condition tracking
- QR code generation for easy identification
- Edit capabilities for authorized users
- Export individual tree reports

## 🔐 Authentication

- Email/password authentication
- Role-based access control (Admin/Worker)
- Secure local session management
- Admin-only features: Delete trees, advanced settings

## 📦 Dependencies

Key packages used:
- `google_maps_flutter` - Interactive maps
- `camera` - Photo capture
- `geolocator` - GPS tracking
- `sqflite` - Local database
- `pdf` - PDF generation
- `excel` - Excel export
- `qr_flutter` - QR code generation
- `shared_preferences` - Local storage
- `connectivity_plus` - Network monitoring

[See pubspec.yaml for complete list]

## 🛠️ Development

### Code Quality
- Follows Flutter style guide
- Modular architecture with separation of concerns
- Comprehensive error handling
- Performance optimized for large datasets

### Testing
Run tests with:
```bash
flutter test
```

### Analysis
Check code quality:
```bash
flutter analyze
```

## 🎯 Future Enhancements

- [ ] Cloud sync with backend API
- [ ] Multi-language support
- [ ] Advanced analytics dashboard
- [ ] Push notifications
- [ ] Species identification via ML
- [ ] Social sharing features

## 📄 License

This project is open source and available under the MIT License.

## 👨‍💻 Author

Developed as a portfolio project demonstrating full-stack mobile development capabilities.

**Skills Demonstrated:**
- Flutter/Dart mobile development
- SQLite database design and management
- Google Maps API integration
- Offline-first architecture
- Custom algorithm implementation (clustering, health calculation)
- Material Design principles
- State management patterns
- Performance optimization
- Git version control

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

## 📞 Contact

For questions or feedback about this project, please open an issue on GitHub.

---

**Note**: This is a demonstration project showcasing mobile app development skills. For production deployment, additional security measures, backend integration, and comprehensive testing would be implemented.
