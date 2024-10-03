import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchReportsPage extends StatefulWidget {
  @override
  _SearchReportsPageState createState() => _SearchReportsPageState();
}

class _SearchReportsPageState extends State<SearchReportsPage> {
  String area = '';
  String crimeType = '';
  List<QueryDocumentSnapshot> _reports = [];

  void _searchReports() async {
    Query query = FirebaseFirestore.instance.collection('reports');

    // Update the query based on the input fields
    if (area.isNotEmpty) {
      query = query.where('address', isEqualTo: area);
    }
    if (crimeType.isNotEmpty) {
      query = query.where('crimeType', isEqualTo: crimeType);
    }

    try {
      QuerySnapshot snapshot = await query.get();
      setState(() {
        _reports = snapshot.docs; // Save the fetched reports
      });
    } catch (e) {
      print('Error fetching reports: $e');
      // Handle error (e.g., show an alert)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Reports'),
      ),
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(labelText: 'Search by Area'),
            onChanged: (value) {
              setState(() {
                area = value;
              });
            },
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Search by Crime Type'),
            onChanged: (value) {
              setState(() {
                crimeType = value;
              });
            },
          ),
          ElevatedButton(
            onPressed: _searchReports,
            child: Text('Search'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                var report = _reports[index].data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(report['crimeType']),
                  subtitle: Text(report['address']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
