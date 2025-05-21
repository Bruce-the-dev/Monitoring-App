# 🚗 Fleet Monitoring App

A Flutter application that displays real-time vehicle locations on Google Maps with rich monitoring, search, and filtering capabilities.

---

## 📱 Features

### 🗺️ Map View

- Interactive Google Map showing all fleet vehicles
- Custom car icons for markers
- Real-time location updates with smooth animations
- Automatic refresh every 5 seconds for moving vehicles

### 🚘 Vehicle Details

- Tap on a vehicle to view:

  - Car name
  - Status: **Moving** or **Parked**
  - Speed (in km/h)
  - Live coordinates (latitude, longitude)
  - A button to zoom in and track movement

### 🔍 Search & Filter

- Floating search bar to find vehicles by name
- Filter by status:

  - All vehicles
  - Moving only
  - Parked only

- Map adjusts automatically to show filtered results

---

## ⚠️ Assumptions & Limitations

- Real-time vehicle updates are **simulated** via periodic API requests.
- Vehicles marked as "Moving" are artificially relocated every 5 seconds.
- **State management using Provider** was initially intended but not implemented in the final version to maintain simplicity and avoid architectural complications during development.
- Marker animation and filtering are handled within the `MaspScreen` logic directly, without external providers or controllers.

---

## 🛠 To run THe App:

Follow these steps to run the app:

1. **Clone the repository**

   ```
   git clone https://github.com/your-username/fleet-monitoring-app.git
   cd fleet-monitoring-app
   ```

2. **Install dependencies**

   ```
   flutter pub get
   ```

3. **Configure Google Maps API Key**

   - Add your API key to:

     - `android/app/src/main/AndroidManifest.xml`
     - `ios/Runner/AppDelegate.swift` or `AppDelegate.m` depending on your platform

   - Refer to [Google Maps Flutter setup guide](https://pub.dev/packages/google_maps_flutter) for details.

4. **Run the app**

   ```
   flutter run
   ```

---

## ✅ Requirements

- Flutter SDK (Latest stable)
- Google Maps API key
- Internet connection for API communication
- Android emulator (API 33+) or physical device
- iOS support (Optional but compatible)

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_maps_flutter: ^2.0.0
  http: ^0.13.0
  material_floating_search_bar_2: ^0.5.0
```

---

## 📸 Screenshots

 ### initial map overview
    ![Initial map over_View](screenshots/map%20overview.jpg)
 ### car details
    ![vehicle detail modal](screenshots/car%20detail.jpg),
 ### search button
    ![search button](screenshots/search%20button.jpg),

---

## 🎥 Demo Video

-     showing how the real time location updates and the smooth animation

[Click here to watch the demo video](screenshots/Demo%20Video.mp4)

---
