import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'add_new_report.dart';
import "search.dart";

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  MapController _mapController = MapController();
  LatLng _userLocation = LatLng(51.505, -0.09); // Default location
  int _selectedIndex = 1; // For highlighting the current item
  bool _isLocationFetched = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;

    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
      if (status.isDenied) {
        print("Location permission denied by the user.");
        return;
      }
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
      return;
    }

    if (status.isGranted) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permission denied forever.");
      return;
    }

    // Get the user's current position
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      print("User Location: ${position.latitude}, ${position.longitude}");

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_userLocation, 13.0);
        _isLocationFetched = true;
      });
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to different routes based on the selected index
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/reports'); // Navigate to ReportsPage
        break;

      case 1:
        // Already on MapPage
        break;

      case 2:
        Navigator.pushNamed(context, '/chats');
        break;
      case 3:
        Navigator.pushNamed(context, '/user');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text('CRISIS MAP'),
        actions: [
          IconButton(
            icon: Icon(Icons.search), // Search icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchReportsPage()),
              );
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _userLocation,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _userLocation,
                width: 40,
                height: 40,
                child: Icon(
                  Icons.location_pin,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // FAB for getting location
          Padding(
            padding: const EdgeInsets.only(left: 20.0, bottom: 20.0),
            child: FloatingActionButton(
              onPressed: () {
                _getCurrentLocation(); // Call the location tracking method
              },
              backgroundColor: Colors.black,
              child: Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          // FAB for recording crime
          Padding(
            padding: const EdgeInsets.only(right: 20.0, bottom: 20.0),
            child: FloatingActionButton(
              onPressed: () {
                // Navigate to CrimeRecordingPage and pass the user location
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CrimeRecordingPage(
                      userLocation: _userLocation,
                    ),
                  ),
                );
              },
              backgroundColor: Colors.green,
              child: Icon(Icons.add_location,
                  color: Colors.white), // Addition with location
            ),
          ),
        ],
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensures all icons are displayed
        backgroundColor: Colors.white, // Matches the background in the image
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications,
                color: Colors.black), // Notification icon
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on,
                color: Colors.red), // Location icon (Highlighted in red)
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message,
                color: Colors.red), // Location icon (Highlighted in red)
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_2_rounded,
                color: Colors.red), // Location icon (Highlighted in red)
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red, // Highlight selected item
        onTap: _onItemTapped,
      ),
    );
  }
}
