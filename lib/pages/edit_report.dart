import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditReportPage extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic> reportData;

  EditReportPage({required this.reportId, required this.reportData});

  @override
  _EditReportPageState createState() => _EditReportPageState();
}

class _EditReportPageState extends State<EditReportPage> {
  late TextEditingController crimeTypeController;
  late TextEditingController descriptionController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    crimeTypeController =
        TextEditingController(text: widget.reportData['crimeType'] ?? '');
    descriptionController =
        TextEditingController(text: widget.reportData['description'] ?? '');
    addressController =
        TextEditingController(text: widget.reportData['address'] ?? '');
  }

  void _updateReport(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId)
          .update({
        'crimeType': crimeTypeController.text,
        'description': descriptionController.text,
        'address': addressController.text,
      });
      Navigator.pop(context); // Go back to the previous screen
    } catch (e) {
      print('Error updating report: $e');
    }
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    crimeTypeController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Report'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: crimeTypeController,
              decoration: InputDecoration(labelText: 'Crime Type'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: addressController,
              decoration: InputDecoration(labelText: 'Location'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _updateReport(context),
              child: Text('Update Report'),
            ),
          ],
        ),
      ),
    );
  }
}
