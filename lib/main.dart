import "package:crisis_management/pages/home_screen_map.dart";
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import "pages/register_screen.dart";
import "pages/onboarding_screens.dart"; // Import the OnBoarding widget
import "pages/home.dart";
import "pages/login_screen.dart";
import "pages/add_new_report.dart";
import 'package:latlong2/latlong.dart'; // Needed for LatLng
import "pages/search.dart";
import "pages/messages.dart";
import "pages/view_report.dart";
import "pages/chat_overview.dart";
import "pages/user_profile.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Onboarding Screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/onboard', // Define the initial route
      routes: {
        '/onboard': (context) => OnBoarding(),
        '/login': (context) => SignInScreen(),
        '/signup': (context) => SignUpScreen(),
        '/home': (context) => HomePage(),
        '/map': (context) => MapPage(),
        '/chats': (context) => ChatOverviewPage(),
        '/report': (context) => CrimeRecordingPage(
              userLocation:
                  LatLng(-1.2921, 36.8219), // Nairobi as an example location
            ),
        '/reports': (context) => ReportsPage(),
        '/messages': (context) => MessagingPage(
              senderId: '',
              receiverId: '',
            ),
        '/search': (context) => SearchReportsPage(),
        '/user': (context) => UserProfilePage(),
      },
    );
  }
}
