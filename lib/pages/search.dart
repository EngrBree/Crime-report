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
      query = query.where('address', isEqualTo: area.toLowerCase());
    }
    if (crimeType.isNotEmpty) {
      query = query.where('crimeType', isEqualTo: crimeType.toLowerCase());
    }

    try {
      QuerySnapshot snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _reports = snapshot.docs;
        });
      } else {
        // No reports found, clear the list
        setState(() {
          _reports = [];
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No reports found')));
      }
    } catch (e) {
      print('Error fetching reports: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching reports')));
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
