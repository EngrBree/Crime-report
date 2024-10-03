import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'messages.dart'; // Import your messaging page
import 'package:rxdart/rxdart.dart'; // Import rxdart

class ChatOverviewPage extends StatelessWidget {
  final String currentUserId =
      FirebaseAuth.instance.currentUser!.uid; // Get the current user ID

  // Method to get unique conversations for the current user
  Stream<List<QuerySnapshot>> _getConversations() {
    final sentMessagesStream = FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', isEqualTo: currentUserId)
        .snapshots();

    final receivedMessagesStream = FirebaseFirestore.instance
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .snapshots();

    // Combine both streams
    return Rx.combineLatest2(
      sentMessagesStream,
      receivedMessagesStream,
      (QuerySnapshot sentMessages, QuerySnapshot receivedMessages) =>
          [sentMessages, receivedMessages],
    );
  }

  // Method to find the other participant in the chat (either sender or receiver)
  String _getOtherParticipant(String senderId, String receiverId) {
    return senderId == currentUserId ? receiverId : senderId;
  }

  // Helper method to get the username for the other participant
  Future<String> _getUsername(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc['name'] ?? 'Unknown User';
      } else {
        return 'Unknown User';
      }
    } catch (e) {
      print("Error fetching username: $e");
      return 'Unknown User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<List<QuerySnapshot>>(
        stream: _getConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No conversations found.'));
          }

          // Store unique conversations by other participant IDs
          Map<String, dynamic> conversationMap = {};

          // Combine messages from both sent and received
          final List<QuerySnapshot> allMessages = snapshot.data!;
          for (var messages in allMessages) {
            for (var doc in messages.docs) {
              var message = doc.data() as Map<String, dynamic>;
              String senderId = message['senderId'];
              String receiverId = message['receiverId'];

              String otherParticipantId =
                  _getOtherParticipant(senderId, receiverId);
              conversationMap[otherParticipantId] = message;
            }
          }

          List<String> uniqueParticipants = conversationMap.keys.toList();

          return ListView.builder(
            itemCount: uniqueParticipants.length,
            itemBuilder: (context, index) {
              String otherUserId = uniqueParticipants[index];

              return FutureBuilder<String>(
                future: _getUsername(otherUserId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Loading...'),
                    );
                  }

                  String username = userSnapshot.data ?? 'Unknown User';

                  return ListTile(
                    leading: CircleAvatar(child: Icon(Icons.person)),
                    title: Text(username),
                    subtitle: Text('Click to view conversation'),
                    onTap: () {
                      // Redirect to the MessagingPage when tapping on a conversation
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessagingPage(
                            senderId: currentUserId,
                            receiverId: otherUserId,
                          ),
                        ),
                      );
                    },
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
