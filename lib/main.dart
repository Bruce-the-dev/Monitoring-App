import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
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

      Set<Marker> markers = {};

      for (var item in data) {
        markers.add(
          Marker(
            markerId: MarkerId(item['id']),
            position: LatLng(
              item['latitude'].toDouble(),
              item['longitude'].toDouble(),
            ),
            icon: _carIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: 'Car name = ${item['name']}',
              snippet:
                  'Status: ${item['status']}', // ADDED: Status in info window
              onTap: () {
                _goToCarDetailsScreen(item);
              },
            ),
          ),
        );
      }

      setState(() {
        _allMarkers = markers; // ADDED: Store all markers
        _filterMarkers(); // ADDED: Apply filters
      });
      _updateCameraToFitMarkers();
    }
  }

  // ADDED: New method for filtering markers
  void _filterMarkers() {
    if (selectedStatus == 'All') {
      _markers = _allMarkers;
    } else {
      _markers =
          _allMarkers.where((marker) {
            var markerId = marker.markerId.value;
            return marker.infoWindow.snippet!.contains(selectedStatus);
          }).toSet();
    }
  }

  void _filterMarkersWithSearch() {
    Set<Marker> filteredMarkers = _allMarkers;

    // Apply status filter
    if (selectedStatus != 'All') {
      filteredMarkers =
          filteredMarkers
              .where(
                (marker) => marker.infoWindow.snippet!.contains(selectedStatus),
              )
              .toSet();
    }

    // Apply search filter
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
    _updateCameraToFitMarkers();
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
                _filterMarkersWithSearch();
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
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Material(
                  color: Colors.white,
                  elevation: 4.0,
                  child: Column(mainAxisSize: MainAxisSize.min, children: []),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
