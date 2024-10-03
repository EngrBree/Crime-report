import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // For formatting date and time
import 'dart:io'; // For handling file I/O
import 'package:permission_handler/permission_handler.dart'; // For camera permissions
import 'package:latlong2/latlong.dart'; // To use LatLng
import 'package:geocoding/geocoding.dart'; // Import geocoding package
import 'package:video_player/video_player.dart'; // Import video player package
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:flutter_spinkit/flutter_spinkit.dart'; // For progress indicator
import '../services/submit_report.dart';
import '../services/select_crime.dart';

class CrimeRecordingPage extends StatefulWidget {
  final LatLng userLocation;

  CrimeRecordingPage({required this.userLocation});

  @override
  _CrimeRecordingPageState createState() => _CrimeRecordingPageState();
}

class _CrimeRecordingPageState extends State<CrimeRecordingPage> {
  File? _mediaFile;
  final picker = ImagePicker();
  bool isAnonymous = false;
  bool isSubmitting = false; // To track submission state
  String? name;
  String _address = 'Fetching location...';
  VideoPlayerController? _videoController;
  String _selectedCrime = "Select a crime";
  TextEditingController _descriptionController = TextEditingController();

  // Fetch username
  Future<void> _fetchUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        name = user.displayName;
      });
    }
  }

  // Show crime selection dialog
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
                      _selectedCrime = crime;
                    });
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Select image/video from gallery
  Future<void> _pickFromGallery() async {
    // Show dialog to choose between image or video
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Media Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Select Image'),
                onTap: () async {
                  final pickedFile =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _mediaFile = File(pickedFile.path);
                      _videoController?.dispose();
                      _videoController = null;
                    });
                  }
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text('Select Video'),
                onTap: () async {
                  final pickedFile =
                      await picker.pickVideo(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _mediaFile = File(pickedFile.path);
                      _videoController = VideoPlayerController.file(_mediaFile!)
                        ..initialize().then((_) {
                          setState(() {});
                        });
                    });
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Capture media (image/video)
  Future<void> _captureMedia() async {
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
                      _videoController?.dispose();
                      _videoController = null;
                    });
                  }
                  Navigator.of(context).pop();
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
                          setState(() {});
                        });
                    });
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Cancel report and clear form
  void _cancelReport() {
    setState(() {
      _mediaFile = null;
      _selectedCrime = "Select a crime";
      _descriptionController.clear();
    });
  }

  // Request camera permissions
  Future<void> _requestPermissions() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      await Permission.camera.request();
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  // Get address from coordinates
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
      setState(() {
        _address = "Failed to get location";
      });
    }
  }

  // Submit report
  Future<void> _submitReport() async {
    String description = _descriptionController.text;

    // Validate fields
    if (description.isEmpty ||
        _selectedCrime == "Select a crime" ||
        _mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields and select media')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      String userId = user?.uid ?? '';
      await SubmitReportService().submitReport(
        userId: userId,
        name: isAnonymous ? 'Anonymous' : name ?? 'Unknown User',
        description: description,
        address: _address,
        date: DateFormat('EEE dd MMM yyyy').format(DateTime.now()),
        time: DateFormat('HH:mm').format(DateTime.now()),
        location: widget.userLocation,
        mediaFile: _mediaFile,
        crimeType: _selectedCrime,
        isAnonymous: isAnonymous,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report submitted successfully')),
      );
      _cancelReport(); // Clear the form after submission
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _fetchUsername();
    _getAddressFromLatLng(widget.userLocation);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _address,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.red),
                      SizedBox(width: 5),
                      Text(currentDate, style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.red),
                      SizedBox(width: 5),
                      Text(currentTime, style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: _selectCrime,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_selectedCrime, style: TextStyle(fontSize: 16)),
                      Icon(Icons.arrow_drop_down, color: Colors.red),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Description of the incident',
                ),
                maxLines: 4,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: Icon(Icons.photo),
                    label: Text('Select Media'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _captureMedia,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Capture Media'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            if (_mediaFile != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _videoController == null
                    ? Image.file(_mediaFile!)
                    : _videoController!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : CircularProgressIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: isAnonymous,
                        onChanged: (bool? value) {
                          setState(() {
                            isAnonymous = value!;
                          });
                        },
                      ),
                      Text('Report anonymously'),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _cancelReport,
                    child: Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitReport,
                child: isSubmitting
                    ? SpinKitThreeBounce(
                        color: Colors.white,
                        size: 20.0,
                      )
                    : Text('Submit Report'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
