import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class MessagingPage extends StatelessWidget {
  final String senderId;
  final String receiverId;

  MessagingPage({required this.senderId, required this.receiverId});

  // Method to get the combined messages stream
  Stream<List<QueryDocumentSnapshot>> _getMessages() {
    // Stream for sent messages
    final sentMessages = FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .snapshots()
        .map((snapshot) => snapshot.docs);

    // Stream for received messages
    final receivedMessages = FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', isEqualTo: receiverId)
        .where('receiverId', isEqualTo: senderId)
        .snapshots()
        .map((snapshot) => snapshot.docs);

    // Combine both streams
    return Rx.combineLatest2(
      sentMessages,
      receivedMessages,
      (List<QueryDocumentSnapshot> sent, List<QueryDocumentSnapshot> received) {
        // Combine and sort both sent and received messages
        return [...sent, ...received]..sort((a, b) {
            Timestamp timeA = a['timestamp'] ?? Timestamp.now();
            Timestamp timeB = b['timestamp'] ?? Timestamp.now();
            return timeA.compareTo(timeB);
          });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: _getMessages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No messages found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var message =
                  snapshot.data![index].data() as Map<String, dynamic>;
              String text = message['text'] ?? '';
              String senderIdFromMessage = message['senderId'];
              bool isMe = senderIdFromMessage ==
                  senderId; // Check if the message is sent by the current user

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.blueAccent
                        : Colors.grey[
                            300], // Different colors for sent and received messages
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(color: isMe ? Colors.white : Colors.black),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar:
          _MessageInputField(senderId: senderId, receiverId: receiverId),
    );
  }
}

// Message Input Field for sending new messages
class _MessageInputField extends StatefulWidget {
  final String senderId;
  final String receiverId;

  _MessageInputField({required this.senderId, required this.receiverId});

  @override
  _MessageInputFieldState createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<_MessageInputField> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('messages').add({
        'senderId': widget.senderId,
        'receiverId': widget.receiverId,
        'text': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
