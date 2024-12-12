import 'package:alertmate/sheets/user_sheets_api.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart'; //For sending location
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; //For calls
import 'package:torch_light/torch_light.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  int? _selectedChipIndex;
  String weatherState = 'Cloudy'; // Default weather state
  String weatherText = "Cloudy";
  String weatherIcon = "cloud"; // Default icon
  String imagePath = 'assets/cloudy.png'; // Default image path
  bool _isFlashlightOn = false; // Track the flashlight state
  bool _isFlickering = false; // Track if the flashlight is flickering
  Timer? _flickerTimer; // Timer for flickering effect
  AudioPlayer _audioPlayer = AudioPlayer(); // Create an instance of AudioPlayer
  bool _isSirenPlaying = false; // Flag to track if the siren is playing
  LinearGradient gradient = const LinearGradient(
    colors: [Color(0xFF73BFC7), Color(0xFF6A8EB4)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  Set<int> _selectedToolCardIndexes =
      {}; // Variable to track selected tool cards

  List<String> weatherStates = [
    "Sunny",
    "Partly Cloudy",
    "Rainy",
    "Thunderstorm",
    "Clear Sky",
    "Partly Cloudy Night"
  ];

  int currentWeatherIndex = 0; // Index to track the current weather state

  void updateWeather() {
    DateTime now = DateTime.now();
    int hour = now.hour; // Get current hour

    String newWeatherState = weatherStates[currentWeatherIndex];
    String newWeatherText = weatherStates[currentWeatherIndex];
    String newWeatherIcon = "default"; // Replace with actual icons for your app
    String newImagePath = 'assets/default.png'; // Replace with default image
    LinearGradient newGradient = const LinearGradient(
      colors: [Color(0xFFE87060), Color(0xFFEB994F)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    // Check the current weather state and update accordingly
    switch (newWeatherState) {
      case "Rainy":
        newWeatherIcon = "rain";
        newImagePath = 'assets/rainy.png';
        newGradient = const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF6BB5F1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
      case "Thunderstorm":
        newWeatherIcon = "thunderstorm";
        newImagePath = 'assets/thunderstorm.png';
        newGradient = const LinearGradient(
          colors: [Color(0xFF505050), Color(0xFF757575)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
      case "Sunny":
        newWeatherIcon = "sun";
        newImagePath = 'assets/sunny.png';
        newGradient = const LinearGradient(
          colors: [Color(0xFFE87060), Color(0xFFEB994F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
      case "Partly Cloudy":
        newWeatherIcon = "cloud";
        newImagePath = 'assets/partly_cloudy_sun.png';
        newGradient = const LinearGradient(
          colors: [Color(0xFFE87060), Color(0xFFEB994F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
      case "Clear Sky":
        newWeatherIcon = "moon";
        newImagePath = 'assets/clear_sky.png';
        newGradient = const LinearGradient(
          colors: [Color(0xFF21407D), Color(0xFF42619F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
      case "Partly Cloudy Night":
        newWeatherIcon = "cloud";
        newImagePath = 'assets/partly_cloudy_night.png';
        newGradient = const LinearGradient(
          colors: [Color(0xFF21407D), Color(0xFF42619F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
    }

    // Update the UI or state with new values
    setState(() {
      weatherState = newWeatherState;
      weatherText = newWeatherText;
      weatherIcon = newWeatherIcon;
      imagePath = newImagePath;
      gradient = newGradient;
    });
  }

  // List of news related to each chip
  final Map<int, List<Map<String, String>>> _newsByChip = {
    0: [
      {
        'image': 'assets/pepito1.jpg',
        'title': 'Typhoon Pepito makes landfall over Cagayan',
        'source': 'INQUIRER.net'
      },
      {
        'image': 'assets/pepito2.jpg',
        'title': 'Bagyong Pepito, nag-landfall sa Sta. Ana, Cagayan',
        'source': 'GMA Integrated News'
      },
    ],
    1: [
      {
        'image': 'assets/kanlaon1.jpg',
        'title': 'Mt. Kanlaon erupts',
        'source': 'Philippine Star'
      },
      {
        'image': 'assets/kanlaon2.jpg',
        'title': 'Kanlaon Alert Level raised',
        'source': 'ABS-CBN News'
      },
    ],
    2: [
      {
        'image': 'assets/taal1.jpg',
        'title': 'Taal Volcano Alert Level Raised to 3',
        'source': 'Philippine Star'
      },
      {
        'image': 'assets/taal2.jpg',
        'title': 'Taal Volcano eruption updates',
        'source': 'GMA News'
      },
    ],
  };

  void _makeCall(String phoneNumber) async {
    final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      throw 'Could not launch call to $phoneNumber';
    }
  }

  Future<void> _sendSmsWithLocation(BuildContext context, String number) async {
    try {
      // Retrieve phone number from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String phone =
          prefs.getString('phone') ?? "Unknown User"; // Retrieve phone number

      // Fetch user profile to get the user's name
      Map<String, String> userProfile =
          await UserSheetsApi.fetchUserProfile(phone);
      String userName = userProfile['name'] ??
          "Unknown User"; // Default to "Unknown User" if name is not found

      // Initial SMS body
      String smsText =
          "This is $userName, and currently I am in danger due to a disaster. My location is below. Please help!";

      // Check for location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Request permission if it is denied
        permission = await Geolocator.requestPermission();
      }

      // If permission is denied forever, notify the user
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Location permissions are permanently denied. Please enable them in settings.')),
        );
        return; // Exit the function if permission is denied forever
      }

      // Get the current location if permission is granted
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        // Append location details to the SMS body
        String locationDescription =
            'I am around this vicinity: Latitude: ${position.latitude}, Longitude: ${position.longitude}\n\n'
            'Copy and paste these coordinates in Google Maps to find my location: ${position.latitude}, ${position.longitude}\n\n'
            '- Sent via AlertMate.';
        smsText += '\n\nLocation description: $locationDescription';

        // Create SMS URI
        Uri smsUri = Uri(
          scheme: 'sms',
          path: number, // Directly use the phone number
          queryParameters: {'body': smsText},
        );

        // Launch the SMS app
        if (await canLaunch(smsUri.toString())) {
          await launch(smsUri.toString());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not send SMS')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is denied')),
        );
      }
    } catch (e) {
      // Handle errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send SMS: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentTime = DateFormat('hh:mm a').format(DateTime.now());
    final String currentDate = DateFormat('EEE MM/dd').format(DateTime.now());

    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: 0), // You can keep or modify this
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(top: 30).add(
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationRow(),
                    const SizedBox(height: 10),
                    _buildWeatherCard(currentTime, currentDate),
                    const SizedBox(height: 15),
                    _buildDiscoverText(),
                    const SizedBox(height: 10),
                    _buildScrollableChips(),
                    const SizedBox(height: 10),
                    _buildNewsCards(),
                    const SizedBox(height: 15),
                    _buildToolText(),
                    _buildGridTools(),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  // Builds the location row
  Row _buildLocationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildLocationIcon(),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Your location",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                SizedBox(height: 0),
                Text("Balagtas, Batangas",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Builds location icon
  Container _buildLocationIcon() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: const Icon(Icons.location_on,
          color: const Color(0xFF52A0A9), size: 25),
    );
  }

  Widget _buildWeatherCard(String currentTime, String currentDate) {
    return GestureDetector(
      onTap: () {
        // Cycle through the weather states when tapped
        setState(() {
          // Increase the index to change weather state
          currentWeatherIndex =
              (currentWeatherIndex + 1) % weatherStates.length;
          updateWeather();
        });
      },
      child: Container(
        height: 165,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeatherRow(currentTime, currentDate),
            const SizedBox(height: 2),
            _buildWeatherDetails(),
          ],
        ),
      ),
    );
  }

  // Builds the weather row with time and date
  Row _buildWeatherRow(String currentTime, String currentDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Check today’s weather",
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(currentTime,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            Text(currentDate,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  // Builds the weather details section (cloudy, temperature, location)
  Row _buildWeatherDetails() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  weatherIcon == "sun"
                      ? Icons.sunny
                      : weatherIcon == "cloud"
                          ? Icons.cloud
                          : Icons.nights_stay,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(weatherText,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 2),
            const Text("26°",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold)),
            const Text("Balagtas, Batangas",
                style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
        const Spacer(),
        // Wrapping the image in a Positioned widget allows it to overlap
        Stack(
          children: [
            Image.asset(
              imagePath,
              width: 100, // Increased width for larger image
              height: 100, // Increased height for larger image
            ),
          ],
        ),
      ],
    );
  }

  // Builds the "Discover" text
  Text _buildDiscoverText() {
    return Text(
      "Discover",
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  // Builds the horizontal scrollable chips
  SingleChildScrollView _buildScrollableChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(0, "Bagyong Pepito"),
          const SizedBox(width: 10),
          _buildChip(1, "Mt. Kanlaon"),
          const SizedBox(width: 10),
          _buildChip(2, "Taal Volcano"),
        ],
      ),
    );
  }

  // Builds a single chip widget
  Widget _buildChip(int index, String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          // If the tapped chip is already selected, deselect it
          _selectedChipIndex = _selectedChipIndex == index ? null : index;
        });
      },
      child: Chip(
        label: Text(label, style: const TextStyle(color: Colors.white)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: _selectedChipIndex == index
            ? const Color(0xFF52A0A9) // Selected chip color
            : const Color(0xFFA4A4A4), // Default color
        padding: const EdgeInsets.only(
          top: 1, // Adjust the top padding as needed
          bottom: 1, // Adjust the bottom padding as needed
          left: 10, // Normal left padding
          right: 10, // Normal right padding
        ),
        materialTapTargetSize:
            MaterialTapTargetSize.shrinkWrap, // Minimize tap target area
      ),
    );
  }

  // Builds the filtered news cards
  SingleChildScrollView _buildNewsCards() {
    // If a chip is selected, show related news; otherwise, show all news
    List<Map<String, String>> newsList = _selectedChipIndex != null
        ? _newsByChip[_selectedChipIndex!] ?? []
        : _newsByChip[0]! + _newsByChip[1]! + _newsByChip[2]!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: newsList.map((news) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child:
                _buildNewsCard(news['image']!, news['title']!, news['source']!),
          );
        }).toList(),
      ),
    );
  }

  // Builds an individual news card with overlayed text on the background image
  Widget _buildNewsCard(String imageUrl, String title, String source) {
    return Container(
      width: 200,
      height: 180,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            // Add a semi-transparent black overlay
            Container(
              decoration: BoxDecoration(
                color:
                    Colors.black.withOpacity(0.5), // 50% opacity black overlay
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                            color: Colors.black,
                            offset: Offset(1, 1),
                            blurRadius: 3),
                      ],
                    ),
                  ),
                  Text(
                    source,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      shadows: [
                        Shadow(
                            color: Colors.black,
                            offset: Offset(1, 1),
                            blurRadius: 3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the "Tools" text
  Text _buildToolText() {
    return Text(
      "Tools",
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  // Builds the grid of tools (including siren)
  GridView _buildGridTools() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      childAspectRatio: 2.4,
      children: [
        _buildToolCard(
          Icons.phone,
          "Emergency Call",
          0,
          onPressed: () => _makeCall('911'),
        ),
        _buildToolCard(
          Icons.textsms,
          "Emergency Text",
          1,
          onPressed: () => _sendSmsWithLocation(context, '911'),
        ),
        _buildToolCard(
          Icons.flashlight_on,
          "Flashlight",
          2,
          onPressed: _toggleFlashlight,
        ),
        _buildToolCard(
          FontAwesomeIcons.bell,
          "Siren",
          3,
          onPressed: _toggleSiren, // Play siren sound on button press
        ),
      ],
    );
  }

  // Function to play the siren sound
  void _toggleSiren() async {
    if (_isSirenPlaying) {
      // If the siren is already playing, stop it
      await _audioPlayer.stop();
    } else {
      // If the siren is not playing, start it and set to loop
      try {
        await _audioPlayer.play(AssetSource('audio/siren.mp3'));

        // Set the audio to loop indefinitely
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      } on Exception catch (_) {
        // Handle any error, e.g., file not found or permission issues
        print("Error occurred while playing the siren sound.");
      }
    }

    // Toggle the state of the siren
    setState(() {
      _isSirenPlaying = !_isSirenPlaying;
    });
  }

  void _toggleFlashlight() async {
    try {
      if (_isFlickering) {
        // If it's flickering, stop it
        _flickerTimer?.cancel();
        await TorchLight.disableTorch(); // Turn off the flashlight
      } else {
        // Start flickering the flashlight
        _flickerTimer =
            Timer.periodic(Duration(milliseconds: 75), (timer) async {
          if (_isFlashlightOn) {
            await TorchLight.disableTorch(); // Turn off the flashlight
          } else {
            await TorchLight.enableTorch(); // Turn on the flashlight
          }
          _isFlashlightOn = !_isFlashlightOn; // Toggle the flashlight state
        });
      }
    } on Exception catch (_) {
      // Handle any errors (e.g., no permission to use the flashlight)
      print("Error occurred while toggling the flashlight.");
    }

    // Update the flickering state
    setState(() {
      _isFlickering = !_isFlickering; // Toggle flickering state
    });
  }

// Builds an individual tool card with adjusted size and layout
  Widget _buildToolCard(IconData icon, String label, int index,
      {VoidCallback? onPressed}) {
    bool shouldToggle =
        index == 2 || index == 3; // Only toggle for Flashlight and Siren
    return GestureDetector(
      onTap: () {
        if (onPressed != null) {
          onPressed(); // Trigger any additional onTap action passed in the parameter
        }
        if (shouldToggle) {
          setState(() {
            // Toggle selection for the clicked tool card
            if (_selectedToolCardIndexes.contains(index)) {
              _selectedToolCardIndexes
                  .remove(index); // Deselect if already selected
            } else {
              _selectedToolCardIndexes
                  .add(index); // Select if not already selected
            }
          });
        }
      },
      child: Card(
        elevation: 5,
        color: _selectedToolCardIndexes.contains(index)
            ? const Color(0xFF52A0A9) // Selected background color
            : const Color(0xFFD9D9D9), // Default background color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          width: 120,
          height: 120, // Adjusted height for the card
          padding: const EdgeInsets.all(8),
          child: Stack(
            children: [
              Positioned(
                top: 4,
                left: 8,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14, // Font size for the label
                    fontWeight: FontWeight.bold,
                    color: _selectedToolCardIndexes.contains(index)
                        ? Colors.white // White text when selected
                        : const Color(0xFF5C5C5C), // Default text color
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 8,
                child: Icon(
                  icon,
                  size: 26, // Increased icon size from the first widget
                  color: _selectedToolCardIndexes.contains(index)
                      ? Colors.white // White icon when selected
                      : const Color(0xFF5C5C5C), // Default icon color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
