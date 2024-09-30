import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

              // Handle null values for report fields
              String userId = report['userId'] ?? '';
              String crimeType = report['crimeType'] ?? 'Unknown crime';
              String description = report['description'] ?? 'No description';
              String address = report['address'] ?? 'Unknown location';
              String date = report['date'] ?? 'Unknown date';
              String time = report['time'] ?? 'Unknown time';
              String mediaUrl = report['mediaUrl'] ?? '';
              String reportId = report['reportId'] ?? '';

              return FutureBuilder<String>(
                future: _getUsername(userId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Loading...'),
                    );
                  }

                  String name = userSnapshot.data ?? 'Unknown User';

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
                        Divider(),
                        _buildCommentsSection(reportId),
                        _buildCommentInputField(reportId),
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

  Widget _buildMediaWidget(String mediaUrl) {
    if (mediaUrl.isEmpty) {
      return SizedBox.shrink(); // Handle empty media URL
    }

    if (mediaUrl.endsWith('.mp4')) {
      return FutureBuilder<VideoPlayerController>(
        future: _initializeVideoController(mediaUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error loading video: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.value.isInitialized) {
            final controller = snapshot.data!;
            return AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            );
          } else {
            return Center(child: Text('Video not available'));
          }
        },
      );
    } else if (mediaUrl.endsWith('.jpg') || mediaUrl.endsWith('.png')) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.network(
          mediaUrl,
          height: 300, // Ensure sufficient height
          fit: BoxFit.cover, // Fit the image to the container
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Text('Error loading image'));
          },
        ),
      );
    } else {
      return SizedBox.shrink(); // Handle invalid media URL
    }
  }

  Future<VideoPlayerController> _initializeVideoController(
      String mediaUrl) async {
    VideoPlayerController controller =
        VideoPlayerController.networkUrl(Uri.parse(mediaUrl));
    await controller.initialize();
    return controller;
  }

  // Display comments section
  Widget _buildCommentsSection(String reportId) {
    if (reportId.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('No comments available.'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('No comments yet.'),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((commentDoc) {
            var comment = commentDoc.data() as Map<String, dynamic>;

            // Handle null values in comments
            String username = comment['username'] ?? 'Unknown User';
            String text = comment['text'] ?? '';
            Timestamp? timestamp = comment['timestamp'];

            return ListTile(
              title: Text(username),
              subtitle: Text(text),
              trailing: Text(
                timestamp != null
                    ? TimeOfDay.fromDateTime(timestamp.toDate()).format(context)
                    : 'Unknown time',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Comment input field
  Widget _buildCommentInputField(String reportId) {
    final TextEditingController _commentController = TextEditingController();

    if (reportId.isEmpty) {
      return SizedBox.shrink(); // Handle empty reportId
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              if (_commentController.text.isNotEmpty) {
                _postComment(reportId, _commentController.text);
                _commentController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  // Post comment to Firestore
  Future<void> _postComment(String reportId, String commentText) async {
    if (commentText.isEmpty || reportId.isEmpty) return; // Ensure valid input

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String username = userDoc['name'] ?? 'Unknown User';

      FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .add({
        'text': commentText,
        'username': username,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }
}
