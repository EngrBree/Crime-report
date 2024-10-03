import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'messages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "edit_report.dart";

class ReportsPage extends StatelessWidget {
  Future<String> _getUsername(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc['name'] ?? 'Unknown User'; // Handle null value
      } else {
        return 'Unknown User'; // User document does not exist
      }
    } catch (e) {
      print("Error fetching username: $e");
      return 'Unknown User'; // Handle error by returning a default value
    }
  }

  // Helper widget to display image or video
  Widget _buildMediaWidget(String mediaUrl) {
    if (mediaUrl.isEmpty) {
      return Container(); // No media to show
    } else if (mediaUrl.endsWith('.mp4')) {
      // Handle video
      return VideoPlayerWidget(mediaUrl: mediaUrl);
    } else {
      // Handle image
      return CachedNetworkImage(
        imageUrl: mediaUrl,
        placeholder: (context, url) => CircularProgressIndicator(),
        errorWidget: (context, url, error) => Icon(Icons.error),
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
  }

  // Function to delete a report
  void _deleteReport(String reportId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .delete();
      print('Report deleted successfully.');
    } catch (e) {
      print('Error deleting report: $e');
    }
  }

  // Function to navigate to the edit page
  void _editReport(
      BuildContext context, String reportId, Map<String, dynamic> reportData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditReportPage(reportId: reportId, reportData: reportData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reports').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No reports found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var report =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              String reportId =
                  snapshot.data!.docs[index].id; // Get the document ID
              String userId = report['userId'] ?? '';
              String crimeType = report['crimeType'] ?? 'Unknown crime';
              String description = report['description'] ?? 'No description';
              String address = report['address'] ?? 'Unknown location';
              String date = report['date'] ?? 'Unknown date';
              String time = report['time'] ?? 'Unknown time';
              String mediaUrl = report['mediaUrl'] ?? '';

              return FutureBuilder<String>(
                future: _getUsername(userId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Loading...'),
                    );
                  }

                  String name = userSnapshot.data ?? 'Unknown User';

                  String senderId =
                      FirebaseAuth.instance.currentUser!.uid.trim();

                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMediaWidget(mediaUrl), // Display media
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Crime Type: $crimeType'),
                              Text('Description: $description'),
                              Text('Location: $address'),
                              Text('Date: $date'),
                              Text('Time: $time'),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Show the message button only if the report sender is not the current user
                            if (userId !=
                                senderId) // Check to avoid messaging yourself
                              IconButton(
                                icon: Icon(Icons.message),
                                onPressed: () {
                                  String receiverId = userId;

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MessagingPage(
                                        senderId: senderId,
                                        receiverId: receiverId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            // Show edit and delete buttons if the report belongs to the current user
                            if (userId ==
                                senderId) // Check if the report is the user's
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () {
                                      _editReport(context, reportId, report);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () {
                                      _deleteReport(reportId);
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// VideoPlayer widget to handle video media
class VideoPlayerWidget extends StatefulWidget {
  final String mediaUrl;

  VideoPlayerWidget({required this.mediaUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();

    // Convert mediaUrl (String) to Uri for the new VideoPlayerController.networkUrl
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.mediaUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isError = false;
          });
          _controller?.play();
        }
      }).catchError((error) {
        print('Error initializing video: $error');
        setState(() {
          _isError = true;
        });
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Center(child: Text('Error loading video.'));
    }

    return _controller != null && _controller!.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          )
        : Center(child: CircularProgressIndicator());
  }
}

// EditReportPage to handle report editing

