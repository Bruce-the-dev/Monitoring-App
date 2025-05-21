# Fleet Monitoring App

This Flutter application will display real-time car locations on a map with detailed monitoring capabilities.

## Features

### Map View

- Interactive Google Maps interface showing all vehicles in the fleet
- Custom car markers with real-time location updates
- Automatic refresh every 5 seconds for moving vehicles

### Vehicle Details

- Tap on any vehicle marker to view detailed information:
  - Car name
  - Current status (Moving/Parked)
  - Speed
  - Current location coordinates
  - Movement tracking option

### Search & Filtering

- Search bar to find vehicles by name
- Status filter to view:
  - All vehicles
  - Only moving vehicles
  - Only parked vehicles
- Dynamic map adjustment to show filtered vehicles

## Getting Started

> In order to run this app you need to follow the following steps

1. Clone this repository
2. Ensure you have Flutter installed on your system
3. Run `flutter pub get` to install dependencies
4. Add your Google Maps API key in the appropriate configuration files
5. Run the app using `flutter run`

## Requirements

- Flutter SDK
- Google Maps API key
- Internet connection for real-time updates
- virtual emulator or any android phone with android 13+
- Compatible with iOS and Android devices

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_maps_flutter: ^2.0.0
  http: ^0.13.0
  material_floating_search_bar_2: ^0.5.0
```
