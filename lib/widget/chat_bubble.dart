import 'package:flutter/material.dart';

class SenderBubble extends StatelessWidget {
  final String message;

  SenderBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          EdgeInsets.only(bottom: 8.0, left: 50.0), // Margin for sender bubble
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.blue[400], // Sender bubble color
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
          bottomLeft: Radius.circular(20.0),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class ReceiverBubble extends StatelessWidget {
  final String message;

  ReceiverBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
          bottom: 8.0, right: 50.0), // Margin for receiver bubble
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white, // Receiver bubble color
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.black),
      ),
    );
  }
}
