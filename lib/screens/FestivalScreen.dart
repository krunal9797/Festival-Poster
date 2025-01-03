import 'package:festival_post/screens/AddBusinessScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ImageViewScreen.dart';

class FestivalScreen extends StatefulWidget {
  @override
  _FestivalScreenState createState() => _FestivalScreenState();
}

class _FestivalScreenState extends State<FestivalScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('festivals');
  Map<String, List<String>> festivalImages = {};

  @override
  void initState() {
    super.initState();
    fetchFestivals();
  }

  // Fetch festival data dynamically from Firebase Realtime Database
  Future<void> fetchFestivals() async {
    DatabaseEvent event = await _dbRef.once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.exists) {
      Map<dynamic, dynamic> festivalsData = snapshot.value as Map<dynamic, dynamic>;

      Map<String, List<String>> imagesData = {};
      festivalsData.forEach((festivalName, festivalData) {
        dynamic festivalImagesData = festivalData['images'];

        List<String> images = [];

        if (festivalImagesData is Map) {
          festivalImagesData.forEach((key, imageUrl) {
            if (imageUrl is String) {
              images.add(imageUrl);
            } else if (imageUrl is Map) {
              imageUrl.forEach((innerKey, innerValue) {
                if (innerValue is String) {
                  images.add(innerValue);
                }
              });
            }
          });
        } else if (festivalImagesData is List) {
          festivalImagesData.forEach((imageUrl) {
            if (imageUrl is String) {
              images.add(imageUrl);
            }
          });
        }

        imagesData[festivalName] = images;
      });

      setState(() {
        festivalImages = imagesData;
      });
    }
  }

  Widget buildImageList(List<String> images) {
    return Container(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () async {
              try {
                final SharedPreferences prefs = await SharedPreferences.getInstance();
                String? businessName = prefs.getString('business_name');
                print("Business Name: $businessName");  // Debugging line

                if (businessName == null || businessName.isEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddBusinessScreen()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageViewScreen(imageUrl: images[index]),
                    ),
                  );
                }
              } catch (e) {
                print("Error accessing SharedPreferences: $e");  // Error handling
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.network(
                images[index],
                fit: BoxFit.cover,
                width: 150,
              ),
            ),
          );
        },
      ),
    );
  }

  void onAddBusinessPressed() {
    // Implement Add Business functionality
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddBusinessScreen()),
    );
    print('Add Business button pressed');
  }

  void onSettingsPressed() {
    // Implement Settings functionality
    print('Settings button pressed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Festival Images'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (festivalImages.isNotEmpty)
              ...festivalImages.entries.map((entry) {
                String festivalName = entry.key;
                List<String> images = entry.value;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align to left and right
                        children: [
                          Text(
                            '${festivalName.toUpperCase()}',  // Capitalized festival name
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '(${images.length})',  // Display the total image count in parentheses
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    buildImageList(images),
                  ],
                );
              }).toList(),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton.icon(
              icon: Icon(Icons.business, color: Colors.blue),
              label: Text('Add Business'),
              onPressed: onAddBusinessPressed,
            ),
            TextButton.icon(
              icon: Icon(Icons.settings, color: Colors.grey),
              label: Text('Settings'),
              onPressed: onSettingsPressed,
            ),
          ],
        ),
      ),

    );
  }
}
