import 'package:alertmate/sheets/user_sheets_api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const AlertPage());
}

class AlertPage extends StatefulWidget {
  const AlertPage({super.key});

  @override
  _AlertPageState createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  final List<Map<String, String>> emergencyContacts = [
    // Hospitals
    {
      "type": "Hospital",
      "name": "Golden Gate Hospital",
      "phone": "(043) 723 2508",
    },
    {
      "type": "Hospital",
      "name": "Batangas Medical Center",
      "phone": "(043) 740 8303",
    },
    {
      "type": "Hospital",
      "name": "St Patricks Hospital Medical Center",
      "phone": "(043) 723 1605 ",
    },
    {
      "type": "Hospital",
      "name": "Batangas Healthcare: Jesus Of Nazareth",
      "phone": "(043) 723 4144",
    },
    {
      "type": "Hospital",
      "name": "United Doctors Of St. Camillus De Lellis",
      "phone": "(043) 740 3087",
    },
    {
      "type": "Hospital",
      "name": "Batangas Healthcare Specialists",
      "phone": "(043) 403 8642",
    },

    // Fire Stations
    {
      "type": "Fire",
      "name": "Batangas City Central Fire Station",
      "phone": "09156021984",
    },
    {
      "type": "Fire",
      "name": "Batangas City Alangilan Fire Station",
      "phone": "402-6449",
    },
    {
      "type": "Fire",
      "name": "Batangas City Poblacion Fire Substation",
      "phone": "(043) 301 7996",
    },

    // Police Stations
    {
      "type": "Crime",
      "name": "Batangas City PS (P. Burgos, Poblacion)",
      "phone": "(043) 723 2030",
    },
    {
      "type": "Crime",
      "name": "Batangas PPO (Pres. Jose P. Laurel Highway, Camp Malvar)",
      "phone": "(043) 980 0400",
    },
    {
      "type": "Crime",
      "name": "Balagtas PAC (Diversion Road, Brgy. Balagtas)",
      "phone": "(043) 402 0454",
    },

    // For Disasters
    {
      "type": "Disaster",
      "name": "City DRRM Office",
      "phone": "(043) 702 3902",
    },
    {
      "type": "Disaster",
      "name": "Batangas Provincial DRRM Office",
      "phone": "(043) 723 9350",
    },
    {
      "type": "Disaster",
      "name": "Provincial DRRM Office",
      "phone": "786-0693",
    },

    // For Utilities
    {
      "type": "Utility",
      "name": "Meralco Batangas",
      "phone": "(02) 16211",
    },
    {
      "type": "Utility",
      "name": "PrimeWater - Batangas City (Alangilan Office)",
      "phone": "(043) 980-6928",
    },
  ];

  String selectedFilter = "All";
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filteredContacts =
        emergencyContacts.where((contact) {
      final matchesType =
          selectedFilter == "All" || contact["type"] == selectedFilter;
      final matchesSearch =
          contact["name"]!.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesType && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alert',
          style: TextStyle(fontWeight: FontWeight.bold), // Bold title
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "All", child: Text("All")),
              const PopupMenuItem(
                value: "Fire",
                child: ListTile(
                  leading: Icon(Icons.local_fire_department,
                      color: Color(0xFF52A0A9)),
                  title: Text("Fire"),
                ),
              ),
              const PopupMenuItem(
                value: "Crime",
                child: ListTile(
                  leading: Icon(Icons.local_police, color: Color(0xFF52A0A9)),
                  title: Text("Crime"),
                ),
              ),
              const PopupMenuItem(
                value: "Hospital",
                child: ListTile(
                  leading: Icon(Icons.local_hospital, color: Color(0xFF52A0A9)),
                  title: Text("Hospital"),
                ),
              ),
              const PopupMenuItem(
                value: "Disaster",
                child: ListTile(
                  leading: Icon(Icons.warning, color: Color(0xFF52A0A9)),
                  title: Text("Disaster"),
                ),
              ),
              const PopupMenuItem(
                value: "Utility",
                child: ListTile(
                  leading: Icon(Icons.bolt, color: Color(0xFF52A0A9)),
                  title: Text("Utility"),
                ),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200], // Light grey background
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey[600]), // Grey hint text
                prefixIcon:
                    Icon(Icons.search, color: Colors.grey[600]), // Grey icon
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none, // No border
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = filteredContacts[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact["name"]!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contact["phone"]!,
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildActionButton(
                                icon: Icons.chat_bubble_outline,
                                label: "Ask help",
                                onPressed: () {
                                  _sendSMS(contact["phone"]!);
                                },
                              ),
                              const SizedBox(width: 4),
                              _buildActionButton(
                                icon: Icons.call,
                                label: "Call",
                                onPressed: () {
                                  _makeCall(contact["phone"]!);
                                },
                              ),
                              const SizedBox(width: 4),
                              _buildActionButton(
                                icon: Icons.share_location,
                                label: "Send my location",
                                onPressed: () => _sendSmsWithLocation(
                                    context, contact["phone"]!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      icon: Icon(icon, size: 18, color: Color(0xFF52A0A9)),
      label: Text(
        label,
        style: TextStyle(fontSize: 12, color: Color(0xFF52A0A9)),
      ),
      style: TextButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF52A0A9),
      ),
      onPressed: onPressed,
    );
  }

  void _sendSMS(String phoneNumber) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      throw 'Could not launch SMS to $phoneNumber';
    }
  }

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
      // Retrieve the logged-in phone number from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String phone = prefs.getString('phone') ?? "Unknown Phone";

      // Fetch the user profile from Google Sheets using the phone number
      Map<String, String> userProfile =
          await UserSheetsApi.fetchUserProfile(phone);
      String userName = userProfile['name'] ?? "Unknown User";

      // Initial SMS body
      String smsText =
          "This is $userName, and currently I am in danger due to a disaster. My location is below. Please help!";

      // Get the current location
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
    } catch (e) {
      // Handle errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send SMS: $e')),
      );
    }
  }
}
