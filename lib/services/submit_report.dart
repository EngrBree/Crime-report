import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import 'dart:io';
import 'package:latlong2/latlong.dart'; // To use LatLng

class SubmitReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage =
      FirebaseStorage.instance; // Initialize Firebase Storage

  // Function to upload the report to Firebase
  Future<void> submitReport({
    required String userId, // Add userId parameter to track the user
    required String name,
    required String description,
    required String address,
    required String date,
    required String time,
    required LatLng location,
    File? mediaFile,
    required String crimeType, // Include crimeType parameter
    bool isAnonymous = false,
  }) async {
    try {
      // Prepare the report data
      Map<String, dynamic> reportData = {
        'name': isAnonymous ? 'Anonymous' : name,
        'userId': userId, // Store userId for tracking
        'description': description,
        'address': address,
        'date': date,
        'time': time,
        'location': GeoPoint(location.latitude, location.longitude),
        'mediaUrl': '', // This will be updated later if media is uploaded
        'isAnonymous': isAnonymous,
        'crimeType': crimeType, // Store the crime type
        'timestamp': FieldValue.serverTimestamp(), // Server timestamp
      };

      // If media is attached, upload it to Firebase Storage and get the URL
      if (mediaFile != null) {
        String mediaUrl = await _uploadMediaToFirebaseStorage(mediaFile);
        reportData['mediaUrl'] = mediaUrl; // Update mediaUrl in reportData
      }

      // Save the report to Firestore
      await _firestore.collection('reports').add(reportData);
    } catch (e) {
      print('Error submitting report: $e');
      throw Exception('Failed to submit report');
    }
  }

  // Function to upload media to Firebase Storage
  Future<String> _uploadMediaToFirebaseStorage(File mediaFile) async {
    try {
      // Create a reference to the storage
      String filePath =
          'reports/${DateTime.now().millisecondsSinceEpoch}_${mediaFile.path.split('/').last}';
      var storageRef = _storage.ref().child(filePath);

      // Upload the file
      await storageRef.putFile(mediaFile);

      // Get the download URL
      String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl; // Return the URL of the uploaded media
    } catch (e) {
      print('Error uploading media: $e');
      throw Exception('Failed to upload media');
    }
  }

  // Example function to retrieve user reports
  Future<List<Map<String, dynamic>>> getUserReports(String userId) async {
    try {
      // Query reports by userId
      QuerySnapshot snapshot = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp',
              descending: true) // Optional: order by timestamp
          .get();

      // Convert documents to a List<Map<String, dynamic>>
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error retrieving reports: $e');
      return [];
    }
  }
}
