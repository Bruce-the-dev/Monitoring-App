import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MapSample());
  }
}

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  _MapSampleState createState() => _MapSampleState();
}

class _MapSampleState extends State<MapSample> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(37.7749, -122.4194);
  Set<Marker> _markers = {};
  BitmapDescriptor? _carIcon;

  // ADDED: New properties for filtering
  String selectedStatus = 'All';
  List<String> statusFilters = ['All', 'Parked', 'Moving'];
  Set<Marker> _allMarkers = {};

  String searchQuery = '';
  late FloatingSearchBarController searchController;
  Map<String, LatLng> _markerPositions = {};

  @override
  void initState() {
    super.initState();
    startUpdatingMovingCars();
    // fetchMarkersFromAPI();
    _loadCarIcon();
    searchController = FloatingSearchBarController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _loadCarIcon() async {
    final BitmapDescriptor carIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/image/carLog.png',
    );
    setState(() {
      _carIcon = carIcon;
    });
  }

  // MODIFIED: Updated fetchMarkersFromAPI
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
        final double newLat = item['latitude'].toDouble();
        final double newLng = item['longitude'].toDouble();
        final LatLng newPosition = LatLng(newLat, newLng);

        // 👇 Store previous position if not present
        _markerPositions.putIfAbsent(id, () => newPosition);

        final LatLng oldPosition = _markerPositions[id]!;

        final hasMoved =
            oldPosition.latitude != newLat || oldPosition.longitude != newLng;

        if (hasMoved) {
          print('Marker $id moved from $oldPosition to $newPosition');
          animateMarkerMovement(id, oldPosition, newPosition);
          _markerPositions[id] =
              newPosition; // 👈 Update to new position after animation starts
        } else {
          updatedMarkers.add(
            Marker(
              markerId: MarkerId(id),
              position: newPosition,
              icon: _carIcon ?? BitmapDescriptor.defaultMarker,
              infoWindow: InfoWindow(
                title: 'Car name = ${item['name']}',
                snippet: 'Status: ${item['status']}',
                onTap: () {
                  _goToCarDetailsScreen(item);
                },
              ),
            ),
          );
        }
      }

      setState(() {
        _allMarkers = updatedMarkers;
        _filterMarkers();
      });
    } else {
      print('Failed to fetch markers: ${response.statusCode}');
    }
  }

  // ADDED: New method for filtering markers
  void _filterMarkers() {
    if (selectedStatus == 'All') {
      _markers = _allMarkers;
    } else {
      _markers =
          _allMarkers.where((marker) {
            return marker.infoWindow.snippet!.contains(selectedStatus);
          }).toSet();
    }
  }

  void _filterMarkersWithSearch({bool adjustCamera = true}) {
    Set<Marker> filteredMarkers = _allMarkers;

    if (selectedStatus != 'All') {
      filteredMarkers =
          filteredMarkers
              .where(
                (marker) => marker.infoWindow.snippet!.contains(selectedStatus),
              )
              .toSet();
    }

    if (searchQuery.isNotEmpty) {
      filteredMarkers =
          filteredMarkers
              .where(
                (marker) => marker.infoWindow.title!.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
              )
              .toSet();
    }

    setState(() {
      _markers = filteredMarkers;
    });

    if (adjustCamera && filteredMarkers.length == 1) {
      // Focus camera on the single search result
      final target = filteredMarkers.first.position;
      mapController.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
    } else if (adjustCamera && filteredMarkers.isNotEmpty) {
      _updateCameraToFitMarkers(); // fallback: fit all filtered markers
    }
  }

  void _updateCameraToFitMarkers() {
    if (_markers.isEmpty) return;

    LatLngBounds bounds;
    final positions = _markers.map((m) => m.position).toList();

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

    bounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );

    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  // MODIFIED: Updated bottom sheet to show status
  void _goToCarDetailsScreen(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Car Name: ${item['name']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Status: ${item['status']}'), // ADDED: Status display
              Text('Speed: ${item['speed']} km/h'),
              SizedBox(height: 8),
              Text('Location: ${item['latitude']}, ${item['longitude']}'),
              ElevatedButton(
                onPressed: () {
                  //TODO tracking function
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text('Track Movement'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    fetchMarkersFromAPI();
    Timer.periodic(Duration(seconds: 5), (timer) {
      fetchMarkersFromAPI();
    });
  }

  // Call this to start periodic updates every 5 seconds
  void startUpdatingMovingCars() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      updateMovingCars();
    });
  }

  // Simulate movement by updating only cars with "Moving" status
  Future<void> updateMovingCars() async {
    final url = Uri.parse(
      'https://6828edd66075e87073a55065.mockapi.io/monitor/cars',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final random = Random();

      for (var car in data) {
        if (car['status'] == 'Moving') {
          final double lat = car['latitude'];
          final double lng = car['longitude'];

          // Slightly change lat/lng to simulate movement
          final double newLat = lat + (random.nextDouble() - 0.5) * 0.001;
          final double newLng = lng + (random.nextDouble() - 0.5) * 0.001;

          final updateUrl = Uri.parse('$url/${car['id']}');
          await http.put(
            updateUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'latitude': newLat, 'longitude': newLng}),
          );
        }
      }

      print('Moving cars updated.');
    } else {
      print('Failed to fetch car data: ${response.statusCode}');
    }
  }

  // MODIFIED: Updated build method with filter button
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple Google Map'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (String status) {
              setState(() {
                selectedStatus = status;
                _filterMarkers();
              });
            },
            itemBuilder: (BuildContext context) {
              return statusFilters.map((String status) {
                return PopupMenuItem<String>(
                  value: status,
                  child: Row(
                    children: [
                      Icon(
                        selectedStatus == status
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 10),
                      Text(status),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center, zoom: 11.0),
            markers: _markers,
          ),
          FloatingSearchBar(
            controller: searchController,
            hint: 'Search vehicles...',
            scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
            transitionDuration: const Duration(milliseconds: 800),
            transitionCurve: Curves.easeInOut,
            physics: const BouncingScrollPhysics(),
            axisAlignment: -1.0,
            openAxisAlignment: 0.0,
            width: 600,
            debounceDelay: const Duration(milliseconds: 500),
            onQueryChanged: (query) {
              setState(() {
                searchQuery = query;
                _filterMarkersWithSearch(adjustCamera: false);
              });
            },
            transition: CircularFloatingSearchBarTransition(),
            actions: [
              FloatingSearchBarAction(
                showIfOpened: false,
                child: CircularButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                ),
              ),
            ],
            builder: (context, transition) {
              final suggestions =
                  _allMarkers
                      .where(
                        (marker) => marker.infoWindow.title!
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase()),
                      )
                      .toList();

              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Material(
                  elevation: 4.0,
                  child: ListView(
                    shrinkWrap: true,
                    children:
                        suggestions.map((marker) {
                          return ListTile(
                            title: Text(marker.infoWindow.title ?? ''),
                            subtitle: Text(marker.infoWindow.snippet ?? ''),
                            onTap: () {
                              searchController.close(); // Close the search bar
                              setState(() {
                                searchQuery = marker.infoWindow.title!;
                                _filterMarkersWithSearch();
                              });

                              mapController.animateCamera(
                                CameraUpdate.newLatLng(marker.position),
                              );
                            },
                          );
                        }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void animateMarkerMovement(String id, LatLng oldPos, LatLng newPos) async {
    const duration = Duration(milliseconds: 1000);
    const steps = 30;
    final stepDuration = duration.inMilliseconds ~/ steps;

    for (int i = 0; i <= steps; i++) {
      final double lat =
          oldPos.latitude + (newPos.latitude - oldPos.latitude) * i / steps;
      final double lng =
          oldPos.longitude + (newPos.longitude - oldPos.longitude) * i / steps;
      final LatLng intermediatePos = LatLng(lat, lng);

      final marker = Marker(
        markerId: MarkerId(id),
        position: intermediatePos,
        icon: _carIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: 'Car ID: $id', snippet: 'Moving...'),
      );

      setState(() {
        _allMarkers.removeWhere((m) => m.markerId.value == id);
        _allMarkers.add(marker);
        _filterMarkers();
      });

      await Future.delayed(Duration(milliseconds: stepDuration));
    }
  }
}
