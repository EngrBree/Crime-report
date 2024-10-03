import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfilePage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> _getUserProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          return userDoc.data() as Map<String, dynamic>; // Return user data
        } else {
          return {}; // Return empty map if no profile found
        }
      } else {
        return {}; // No user is logged in
      }
    } catch (e) {
      print("Error fetching user profile: $e");
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching profile.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No user profile found.'));
          }

          // Extract data
          Map<String, dynamic> userData = snapshot.data!;
          String name = userData['name'] ?? 'No name provided';
          String email = userData['email'] ?? 'No email provided';
          String phone = userData['phone'] ?? 'No phone provided';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: $name', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Email: $email', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Phone: $phone', style: TextStyle(fontSize: 18)),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await _auth.signOut();
                    Navigator.pushReplacementNamed(
                        context, '/onboard'); // Go back to the previous screen
                  },
                  child: Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.red, // Background color
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
