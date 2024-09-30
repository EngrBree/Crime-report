import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';

class OnBoarding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: OnBoardingSlider(
        headerBackgroundColor: Colors.white,
        skipTextButton: Text('Skip'),
        background: [
          // Wrap each image in a container to set the background color
          Container(
            color: Colors.white,
            child: Image.asset('assets/images/pic1.jpeg'),
          ),
          Container(
            color: Colors.red,
            child: Image.asset('assets/images/pic2.jpeg'),
          ),
          Container(
            color: Colors.white,
            child: Image.asset('assets/images/pic3.jpeg'),
          ),
        ],
        totalPage: 3,
        speed: 1.8,
        pageBodies: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20), // Adjusted padding
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 238, 236, 236), // Red background
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center the content vertically
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align text to the left
              children: <Widget>[
                // Image at the top
                Center(
                  child: Image.asset(
                    'assets/images/pic1.jpeg', // Replace with the correct image for slide 2
                    height: 200, // Adjust height as necessary
                  ),
                ),
                SizedBox(height: 30), // Spacing between image and text
                // Title text
                Text(
                  'Capture what you see',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold, // Make the title bold
                    color: Color.fromARGB(
                        255, 124, 7, 3), // White text for contrast
                  ),
                ),
                SizedBox(height: 10), // Spacing between title and description
                // Description text
                Text(
                  'See anything werid going on??',
                  style: TextStyle(
                    fontSize: 16, // Smaller font size for description
                    color: Color.fromARGB(129, 20, 20,
                        20), // Slightly lighter white for description
                  ),
                ),
                SizedBox(height: 10), // Spacing between paragraphs
                Text(
                  'Capture a video or picture and post it ',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color.fromARGB(
                        179, 2, 2, 2), // White text for readability
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20), // Adjusted padding
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 153, 13, 3), // Red background
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center the content vertically
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align text to the left
              children: <Widget>[
                // Image at the top
                Center(
                  child: Image.asset(
                    'assets/images/pic2.jpeg', // Replace with the correct image for slide 2
                    height: 200, // Adjust height as necessary
                  ),
                ),
                SizedBox(height: 30), // Spacing between image and text
                // Title text
                Text(
                  'Express your Sight',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold, // Make the title bold
                    color: Colors.white, // White text for contrast
                  ),
                ),
                SizedBox(height: 10), // Spacing between title and description
                // Description text
                Text(
                  'Give the description of anything illegal you hav seen.',
                  style: TextStyle(
                    fontSize: 16, // Smaller font size for description
                    color: Colors
                        .white70, // Slightly lighter white for description
                  ),
                ),
                SizedBox(height: 10), // Spacing between paragraphs
                Text(
                  'Express in a way the prople can understand ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70, // White text for readability
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white, // White background
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // Title text
                Text(
                  'Submit the CrisisEmergency',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold, // Bold title
                    color: Colors.red, // Red color for the title
                  ),
                ),
                SizedBox(height: 10), // Spacing between title and subtitle
                // Subtitle text
                Text(
                  'Report any Crisis at your current location',
                  style: TextStyle(
                    fontSize: 18, // Smaller font size for subtitle
                    color: Colors.blueGrey, // Subtitle color
                  ),
                  textAlign: TextAlign.center, // Centered text
                ),
                SizedBox(height: 30), // Spacing between subtitle and button
                // "Get Started" Button
                ElevatedButton(
                  onPressed: () {
                    // Redirect to the sign-up page
                    Navigator.pushNamed(context,
                        '/login'); // Make sure the route is defined in your app
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Color.fromARGB(
                        255, 87, 8, 2), // Red background color for the button
                    padding: EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15), // Button padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Rounded button
                    ),
                  ),
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      color: const Color.fromARGB(
                          255, 3, 3, 3), // White text on the button
                    ),
                  ),
                ),
                SizedBox(
                    height: 50), // Spacing between the button and the image
                // Bottom image
                Expanded(
                  child: Image.asset(
                    'assets/images/pic3.jpeg', // Replace with the correct image for slide 3
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
