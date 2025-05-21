// TODO Implement this library.
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(37.7749, -122.4194);

  Set<Marker> _markers = {};
  Set<Marker> _allMarkers = {};
  final Map<String, LatLng> _markerPositions = {};
  BitmapDescriptor? _carIcon;

  List<String> statusFilters = ['All', 'Parked', 'Moving'];
  String selectedStatus = 'All';
  String searchQuery = '';
  late FloatingSearchBarController searchController;

  @override
  void initState() {
    super.initState();
    searchController = FloatingSearchBarController();
    _loadCarIcon();
    fetchMarkersFromAPI();
    startMovingCarsSimulation();
    Timer.periodic(const Duration(seconds: 5), (_) => fetchMarkersFromAPI());
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCarIcon() async {
    _carIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/image/carLog.png',
    );
  }

  void fetchMarkersFromAPI() async {
    final url = Uri.parse(
      'https://6828edd66075e87073a55065.mockapi.io/monitor/cars',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      Set<Marker> updatedMarkers = {};

      for (var item in data) {
        final String id = item['id'];
        final LatLng newPosition = LatLng(item['latitude'], item['longitude']);
        _markerPositions.putIfAbsent(id, () => newPosition);

        final LatLng oldPosition = _markerPositions[id]!;
        final bool hasMoved = oldPosition != newPosition;

        if (hasMoved) {
          animateMarkerMovement(id, oldPosition, newPosition, item);
          _markerPositions[id] = newPosition;
        } else {
          updatedMarkers.add(_buildMarker(id, newPosition, item));
        }
      }

      setState(() {
        _allMarkers = updatedMarkers;
        _applyFilters();
      });
    }
  }

  Marker _buildMarker(String id, LatLng position, Map item) {
    return Marker(
      markerId: MarkerId(id),
      position: position,
      icon: _carIcon ?? BitmapDescriptor.defaultMarker,
      infoWindow: InfoWindow(
        title: 'Car name = ${item['name']}',
        snippet: 'Status: ${item['status']}',
        onTap: () => _showCarDetails(item),
      ),
    );
  }

  void animateMarkerMovement(
    String id,
    LatLng oldPos,
    LatLng newPos,
    Map item,
  ) async {
    const duration = Duration(milliseconds: 1000);
    const steps = 30;
    final stepDuration = duration.inMilliseconds ~/ steps;

    for (int i = 0; i <= steps; i++) {
      final lat =
          oldPos.latitude + (newPos.latitude - oldPos.latitude) * i / steps;
      final lng =
          oldPos.longitude + (newPos.longitude - oldPos.longitude) * i / steps;
      final intermediatePos = LatLng(lat, lng);

      final marker = _buildMarker(id, intermediatePos, item);

      setState(() {
        _allMarkers.removeWhere((m) => m.markerId.value == id);
        _allMarkers.add(marker);
        _applyFilters();
      });

      await Future.delayed(Duration(milliseconds: stepDuration));
    }
  }

  void _applyFilters({bool adjustCamera = false}) {
    Set<Marker> filtered = _allMarkers;

    if (selectedStatus != 'All') {
      filtered =
          filtered
              .where((m) => m.infoWindow.snippet!.contains(selectedStatus))
              .toSet();
    }

    if (searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (m) => m.infoWindow.title!.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
              )
              .toSet();
    }

    setState(() {
      _markers = filtered;
    });

    if (adjustCamera && filtered.isNotEmpty) {
      _updateCamera(filtered);
    }
  }

  void _updateCamera(Set<Marker> markers) {
    if (markers.length == 1) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(markers.first.position, 15),
      );
      return;
    }

    final bounds = _getBounds(markers.map((m) => m.position).toList());
    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  LatLngBounds _getBounds(List<LatLng> positions) {
    double south = positions.first.latitude;
    double north = positions.first.latitude;
    double west = positions.first.longitude;
    double east = positions.first.longitude;

    for (var pos in positions) {
      if (pos.latitude > north) north = pos.latitude;
      if (pos.latitude < south) south = pos.latitude;
      if (pos.longitude > east) east = pos.longitude;
      if (pos.longitude < west) west = pos.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  void _showCarDetails(Map item) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Car Name: ${item['name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Status: ${item['status']}'),
                Text('Speed: ${item['speed']} km/h'),
                Text('Location: ${item['latitude']}, ${item['longitude']}'),
                ElevatedButton(
                  onPressed: () => _trackCar(item),
                  child: const Text('Track Movement'),
                ),
              ],
            ),
          ),
    );
  }

  void _trackCar(Map item) {
    final marker = _allMarkers.firstWhere(
      (m) => m.markerId.value == item['id'],
    );
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(marker.position, 19),
    );
  }

  void startMovingCarsSimulation() {
    Timer.periodic(const Duration(seconds: 5), (_) => _simulateMovingCars());
  }

  Future<void> _simulateMovingCars() async {
    final url = Uri.parse(
      'https://6828edd66075e87073a55065.mockapi.io/monitor/cars',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final rand = Random();

      for (var car in data) {
        if (car['status'] == 'Moving') {
          final newLat = car['latitude'] + (rand.nextDouble() - 0.5) * 0.001;
          final newLng = car['longitude'] + (rand.nextDouble() - 0.5) * 0.001;

          await http.put(
            Uri.parse('$url/${car['id']}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'latitude': newLat, 'longitude': newLng}),
          );
        }
      }
    }
  }

  void _resetApp() {
    setState(() {
      searchQuery = '';
      selectedStatus = 'All';
      searchController.clear();
      _applyFilters(adjustCamera: true);
    });

    // Fetch fresh data from API
    fetchMarkersFromAPI();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Tracker'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetApp,
            tooltip: 'Reset all filters',
          ),
          // Existing filter button
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              selectedStatus = value;
              _applyFilters();
            },
            itemBuilder:
                (_) =>
                    statusFilters
                        .map(
                          (status) =>
                              PopupMenuItem(value: status, child: Text(status)),
                        )
                        .toList(),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => mapController = controller,
            initialCameraPosition: CameraPosition(target: _center, zoom: 11),
            markers: _markers,
          ),
          FloatingSearchBar(
            controller: searchController,
            hint: 'Search vehicles...',
            transitionDuration: const Duration(milliseconds: 500),
            debounceDelay: const Duration(milliseconds: 300),
            onQueryChanged: (query) {
              searchQuery = query;
              _applyFilters(adjustCamera: false);
            },
            builder: (context, _) {
              final suggestions =
                  _allMarkers
                      .where(
                        (m) => m.infoWindow.title!.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();
              return Material(
                elevation: 4,
                child: ListView.builder(
                  itemCount: suggestions.length,
                  shrinkWrap: true,
                  itemBuilder: (_, i) {
                    final marker = suggestions[i];
                    return ListTile(
                      title: Text(marker.infoWindow.title ?? ''),
                      subtitle: Text(marker.infoWindow.snippet ?? ''),
                      onTap: () {
                        searchQuery = marker.infoWindow.title!;
                        searchController.close();
                        _applyFilters(adjustCamera: true);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
