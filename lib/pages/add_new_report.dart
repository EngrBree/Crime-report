import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // For formatting date and time
import 'dart:io'; // For handling file I/O
import 'package:permission_handler/permission_handler.dart'; // For camera permissions
import 'package:latlong2/latlong.dart'; // To use LatLng
import 'package:geocoding/geocoding.dart'; // Import geocoding package
import 'package:video_player/video_player.dart'; // Import video player package
import "../services/submit_report.dart";
import "../services/select_crime.dart";
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class CrimeRecordingPage extends StatefulWidget {
  final LatLng userLocation; // Add userLocation parameter

  CrimeRecordingPage({required this.userLocation}); // Constructor

  @override
  _CrimeRecordingPageState createState() => _CrimeRecordingPageState();
}

class _CrimeRecordingPageState extends State<CrimeRecordingPage> {
  File? _mediaFile; // To hold the selected image or video
  final picker = ImagePicker();
  bool isAnonymous = false; // Toggle for reporting as anonymous
  String? name; // To hold the actual username
  String _address = 'Fetching location...';
  VideoPlayerController? _videoController; // Controller for video playback
  String _selectedCrime = "Select a crime"; // To hold the selected crime

  TextEditingController _descriptionController = TextEditingController();

  // Function to fetch the username
  Future<void> _fetchUsername() async {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user != null) {
      setState(() {
        name = user.displayName; // Set the username
      });
    }
  }

  // Function to show crime selection dialog
  Future<void> _selectCrime() async {
    final List<String> crimes = CrimeService().getAvailableCrimes();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Crime'),
          content: SingleChildScrollView(
            child: ListBody(
              children: crimes.map((crime) {
                return ListTile(
                  title: Text(crime),
                  onTap: () {
                    setState(() {
                      _selectedCrime = crime; // Update the selected crime
                    });
                    Navigator.of(context).pop(); // Close the dialog
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Function to pick image/video from gallery
  Future<void> _pickFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _mediaFile = File(pickedFile.path);
      });
    }
  }

  // Function to capture image/video from camera
  Future<void> _captureMedia() async {
    // Show a dialog to choose between image or video
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Media Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Capture Image'),
                onTap: () async {
                  final pickedFile =
                      await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() {
                      _mediaFile = File(pickedFile.path);
                      if (_videoController != null) {
                        _videoController!.dispose();
                        _videoController = null;
                      }
                    });
                  }
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
              ListTile(
                title: Text('Record Video'),
                onTap: () async {
                  final pickedFile =
                      await picker.pickVideo(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() {
                      _mediaFile = File(pickedFile.path);
                      _videoController = VideoPlayerController.file(_mediaFile!)
                        ..initialize().then((_) {
                          setState(() {}); // Refresh to display the video
                        });
                    });
                  }
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Ask for camera permissions
  Future<void> _requestPermissions() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      // Request permission if denied previously
      await Permission.camera.request();
    }
    if (status.isGranted) {
      // Permissions are granted
    } else if (status.isPermanentlyDenied) {
      // Show dialog to ask the user to enable from settings
      await openAppSettings();
    }
  }

  // Function to get address from coordinates
  Future<void> _getAddressFromLatLng(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      Placemark place = placemarks[0];
      setState(() {
        _address =
            "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      });
    } catch (e) {
      print(e);
      setState(() {
        _address = "Failed to get location";
      });
    }
  }

  // Function to submit the report
  Future<void> _submitReport() async {
    String description = _descriptionController.text;

    if (description.isEmpty || _selectedCrime == "Select a crime") {
      // Show a message if the description is empty or crime is not selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please provide a description and select a crime')),
      );
      return;
    }

    try {
      // Fetch the current user's ID
      User? user = FirebaseAuth.instance.currentUser; // Get the current user
      String userId = user?.uid ??
          ''; // Get user ID or use an empty string if not authenticated

      // Use the SubmitReportService to send the report
      await SubmitReportService().submitReport(
        userId: userId, // Include userId to track the report
        name: isAnonymous ? 'Anonymous' : name ?? 'Unknown User',
        description: description,
        address: _address,
        date: DateFormat('EEE dd MMM yyyy').format(DateTime.now()),
        time: DateFormat('HH:mm').format(DateTime.now()),
        location: widget.userLocation,
        mediaFile: _mediaFile,
        crimeType: _selectedCrime, // Make sure to include this
        isAnonymous: isAnonymous,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report submitted successfully')),
      );

      // Optionally clear the form after submission
      _descriptionController.clear();
      setState(() {
        _mediaFile = null;
        _selectedCrime = "Select a crime"; // Reset crime selection
      });
    } catch (e) {
      // Handle errors (e.g., network issues)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions(); // Request camera permissions on app startup
    _fetchUsername(); // Fetch username from Firebase Auth
    _getAddressFromLatLng(widget.userLocation); // Fetch the address
  }

  @override
  void dispose() {
    if (_videoController != null) {
      _videoController!.dispose(); // Dispose the video controller
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current date and time
    String currentDate = DateFormat('EEE dd MMM yyyy').format(DateTime.now());
    String currentTime = DateFormat('HH:mm').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('REPORT INCIDENT'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Location display
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _address, // Display the dynamically fetched address
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Date and Time display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(currentDate),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(currentTime),
                    ],
                  ),
                ],
              ),
            ),
            // Select Crime Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _selectCrime,
                child: Text(_selectedCrime), // Display selected crime
              ),
            ),
            // Description Input Field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Description of the incident...',
                ),
              ),
            ),
            // Anonymous Checkbox
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Checkbox(
                    value: isAnonymous,
                    onChanged: (value) {
                      setState(() {
                        isAnonymous = value!;
                      });
                    },
                  ),
                  Text('Report anonymously'),
                ],
              ),
            ),
            // Media Selection Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _pickFromGallery,
                    child: Text('Select Media'),
                  ),
                  ElevatedButton(
                    onPressed: _captureMedia,
                    child: Text('Capture Media'),
                  ),
                ],
              ),
            ),
            // Display selected media
            if (_mediaFile != null) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _mediaFile!.path.endsWith('.mp4')
                    ? _videoController != null &&
                            _videoController!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : Container() // Placeholder while loading
                    : Image.file(_mediaFile!), // Display selected image
              ),
            ],
            // Submit Button
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _submitReport,
                  child: Text('Submit Report'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
