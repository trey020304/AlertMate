import 'package:alertmate/constants.dart';
import 'package:alertmate/sheets/user_sheets_api.dart';
import 'package:alertmate/ui/login_page.dart';
import 'package:flutter/material.dart';
/*import 'package:image_picker/image_picker.dart';*/
import 'package:shared_preferences/shared_preferences.dart';
/*import 'dart:io';*/ //File type
import 'dart:convert'; //For JSON decode
import 'package:url_launcher/url_launcher.dart'; //For calls
import 'package:geolocator/geolocator.dart'; //For sending location
import 'package:flutter/services.dart'; // For limiting characters on text field

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // Controllers for editing fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final String _userNameKey = 'userName';
  final String _userContactKey = 'userContact';
  final String _userAddressKey = 'userAddress';

  String get userName => nameController.text; // Getter to expose userName
  bool _isEditing = false;

  // List to store emergency contacts
  List<Map<String, String>> emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    _loadUserDetails(); // Load saved user details on initialization
    _loadProfileData(); // Load profile data from Google Sheets
    _loadEmergencyContacts(); // Load emergency contacts
  }

  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? phone = prefs.getString('phone'); // Retrieve the saved phone number

    if (phone != null) {
      // Fetch the profile data for the logged-in user based on the phone number
      final profileData = await UserSheetsApi.fetchUserProfile(phone);

      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          nameController.text = profileData['name'] ?? ''; // Use empty if null
          // Add the +63 prefix only for display purposes
          contactController.text =
              '+63' + (profileData['phone'] ?? phone); // Fallback to phone
          addressController.text = profileData['address'] ?? '';
        });
      }
    } else {
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          // If no phone is saved in preferences, ensure contactController is empty
          contactController.text = '';
        });
      }
    }
  }

  Future<void> _loadEmergencyContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userPhone = prefs.getString('phone') ?? '';

    if (userPhone.isEmpty) {
      throw Exception('User is not logged in.');
    }

    try {
      // Fetch contacts from Google Sheets for the logged-in user
      final fetchedContacts =
          await UserSheetsApi.fetchContactsForUser(userPhone);

      setState(() {
        // Update the emergencyContacts list and add + prefix to phone numbers
        emergencyContacts = fetchedContacts.map((contact) {
          // Remove non-digit characters
          String cleanedNumber =
              contact['number']!.replaceAll(RegExp(r'\D'), '');

          // Add the "+" prefix if not already present
          if (contact['number'] != null &&
              !contact['number']!.startsWith('+')) {
            contact['number'] = '+' + cleanedNumber; // Add "+" if not present
          } else {
            // Ensure the number is treated as a non-nullable String
            contact['number'] = contact[
                'number']!; // Use the original number if it already has "+"
          }

          return contact;
        }).toList();
      });
    } catch (e) {
      print('Error loading contacts: $e');
    }
  }

  // Function to load user details from SharedPreferences
  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text = prefs.getString(_userNameKey) ?? '';
      contactController.text = prefs.getString(_userContactKey) ?? '';
      addressController.text = prefs.getString(_userAddressKey) ?? '';
    });
  }

  // Save emergency contacts to SharedPreferences
  Future<void> _saveEmergencyContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userPhone = prefs.getString('phone') ?? '';

    if (userPhone.isEmpty) {
      throw Exception('User is not logged in.');
    }

    String jsonContacts = jsonEncode(emergencyContacts);
    await prefs.setString('emergencyContacts', jsonContacts);

    // Save to Google Sheets without the +63 prefix
    for (var contact in emergencyContacts) {
      String numberWithoutPrefix = contact['number']!
          .replaceAll(RegExp(r'\D'), ''); // Remove non-digit characters

      // Save to Google Sheets without the +63 prefix
      await UserSheetsApi.addOrUpdateContactOnSheets(
        userPhone,
        contact['currentNumber'] ??
            numberWithoutPrefix, // Store number without prefix in Google Sheets
        contact['name']!,
        numberWithoutPrefix, // Store number without prefix in Google Sheets
      );
    }
  }

  // Future<void> _addOrUpdateContactOnSheets(
  //     String currentNumber, String name, String number) async {
  //   try {
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     final userPhone = prefs.getString('phone') ?? '';

  //     if (userPhone.isEmpty) {
  //       throw Exception('User is not logged in');
  //     }

  //     await UserSheetsApi.addOrUpdateContactOnSheets(
  //       userPhone,
  //       currentNumber,
  //       name,
  //       number,
  //     );

  //     print('Contact updated successfully.');
  //   } catch (e) {
  //     print('Error updating contact: $e');
  //   }
  // }

  // Function to save and update the user details
  Future<void> _saveUserDetails(String updatedPhone) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String name = nameController.text;
    String newPhone = updatedPhone; // Add the +63 prefix here for Google Sheets
    String address = addressController.text;

    // Retrieve the current phone number from SharedPreferences
    String? currentPhone = prefs.getString('phone');

    if (currentPhone != null) {
      if (currentPhone != newPhone) {
        try {
          // Phone number has changed; update all instances in Google Sheets
          await UserSheetsApi.updateAllPhoneNumberInstances(
              currentPhone, newPhone);

          // Update the user's profile in Google Sheets
          await UserSheetsApi.updateUserProfile(
              currentPhone, newPhone, name, address);

          // Update the phone number in SharedPreferences
          await prefs.setString('phone', newPhone);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number updated successfully.')),
          );
        } catch (e) {
          // Handle errors during the update process
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating phone number: $e')),
          );
        }
      } else {
        try {
          // Phone number has not changed; update other details
          await UserSheetsApi.updateUserProfile(
              currentPhone, newPhone, name, address);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Details updated successfully.')),
          );
        } catch (e) {
          // Handle errors during the profile update process
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating details: $e')),
          );
        }
      }
    }
  }

  void onEdit(int index, String updatedName, String updatedNumber) {
    setState(() {
      // Update the 'currentNumber' to track the last known number
      emergencyContacts[index] = {
        'currentNumber': emergencyContacts[index]['number']!,
        'name': updatedName,
        'number': updatedNumber,
      };
    });
    _saveEmergencyContacts(); // Save locally and update Google Sheets
  }

  void deleteContact(int index) async {
    // Get the phone number of the contact to be deleted
    String contactPhone = emergencyContacts[index]['number']!;

    setState(() {
      emergencyContacts.removeAt(index); // Remove contact from the local list
    });

    // Save the updated list to SharedPreferences
    await _saveEmergencyContacts();

    // Delete the contact from Google Sheets
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userPhone = prefs.getString('phone') ?? '';

    if (userPhone.isEmpty) {
      throw Exception('User is not logged in.');
    }

    try {
      await UserSheetsApi.deleteContactFromSheets(userPhone, contactPhone);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Contact deleted successfully from Google Sheets.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error deleting contact from Google Sheets: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Constants.bgColor,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Make the title bold
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit), // Pencil icon
            onPressed: () {
              _showEditDialog(context); // Show the edit dialog
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Row(
              children: [
                const SizedBox(width: 40),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nameController.text,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      contactController.text,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Personal Information Section
            const Text(
              'Personal Information',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Contact number',
              style: TextStyle(fontSize: 12, color: Constants.cyanColor),
            ),
            Row(
              children: [
                Text(
                  contactController.text,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Address',
              style: TextStyle(fontSize: 12, color: Constants.cyanColor),
            ),
            Text(
              addressController.text,
              style: const TextStyle(fontSize: 16, height: 1.25),
            ),
            const SizedBox(height: 24),
            // Emergency Contacts Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Emergency contacts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert), // Ellipsis icon
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize:
                                MainAxisSize.min, // Make the dialog compact
                            children: [
                              ListTile(
                                leading:
                                    Icon(Icons.add, color: Constants.cyanColor),
                                title: const Text('Add contact',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                onTap: () {
                                  Navigator.pop(
                                      context); // Close the bottom sheet
                                  _addEmergencyContact(); // Call the add contact dialog
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.edit,
                                    color: Constants.cyanColor),
                                title: Text(
                                  'Toggle edit contact (${_isEditing ? 'OFF' : 'ON'})',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                onTap: () {
                                  Navigator.pop(
                                      context); // Close the bottom sheet
                                  setState(() {
                                    _isEditing =
                                        !_isEditing; // Toggle editing state
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: const TextSpan(
                text:
                    'Emergency contacts are people you trust to help you in an emergency. ',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.25), // Default style
                children: [
                  TextSpan(
                    text: 'They’ll be contacted if you start an ',
                  ),
                  TextSpan(
                    text: 'emergency sharing',
                    style: TextStyle(fontWeight: FontWeight.bold), // Bold style
                  ),
                  TextSpan(
                    text:
                        '. You can also show them on the Lock screen for quick access in an emergency.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Emergency Contacts List (Scrollable)
            SizedBox(
              height: 353, // Set the height for the list
              child: ListView.builder(
                itemCount: emergencyContacts.length,
                itemBuilder: (context, index) {
                  return ContactCard(
                    name: emergencyContacts[index]['name']!,
                    number: emergencyContacts[index]['number']!,
                    isEditing: _isEditing, // Pass the selectedContactIndex here
                    onDelete: () {
                      // Handle delete functionality here
                      deleteContact(index); // Call a method to handle deletion
                    },
                    onEdit: (updatedName, updatedNumber) {
                      onEdit(index, updatedName,
                          updatedNumber); // Pass the edit function here
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Retrieve the current phone number (with +63) to display in the dialog
        String currentPhone = contactController.text;
        String cleanedPhone = currentPhone.replaceFirst(
            '+63', ''); // Remove the +63 prefix for editing

        return AlertDialog(
          title: const Text('Edit Personal Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              )),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                        20), // Limit to 20 characters
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contactController
                    ..text = cleanedPhone, // Set cleaned phone
                  decoration: const InputDecoration(
                      prefixText: '(+63)', labelText: 'Contact Number'),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                        10), // Limit to 10 characters
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog without saving
              },
              child: Text('Cancel',
                  style: TextStyle(fontSize: 16, color: Constants.cyanColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                String updatedPhone =
                    contactController.text.replaceFirst('+63', '');

                // Check if the phone number already exists in the Google Sheets
                bool phoneExists =
                    await UserSheetsApi.checkPhoneOnGoogleSheets(updatedPhone);

                if (phoneExists) {
                  // Show a prompt if the phone number already exists
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Phone Number Exists'),
                        content: const Text(
                            'The phone number already exists in the system. Please try a different number.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  // If phone does not exist, save updated details
                  setState(() {
                    _saveUserDetails(
                        updatedPhone); // Pass the cleaned phone number
                  });

                  // Update the contactController with the new phone number prefixed with +63
                  String updatedPhoneWithPrefix =
                      '+63' + contactController.text;
                  setState(() {
                    contactController.text = updatedPhoneWithPrefix;
                  });

                  Navigator.of(context).pop(); // Close dialog
                }
              },
              child: Text('Save',
                  style: TextStyle(fontSize: 16, color: Constants.cyanColor)),
            ),
          ],
        );
      },
    );
  }

  // Function to show the dialog to add an emergency contact
  void _addEmergencyContact({Map<String, String>? existingContact}) {
    final TextEditingController nameController =
        TextEditingController(text: existingContact?['name'] ?? '');
    final TextEditingController numberController =
        TextEditingController(text: existingContact?['number'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            existingContact != null
                ? 'Update Emergency Contact'
                : 'Add Emergency Contact',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                      20), // Limit to 20 characters
                ],
              ),
              TextField(
                controller: numberController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  prefixText: '(+63)',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                      10), // Limit to 20 characters
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    numberController.text.isNotEmpty) {
                  // Ensure the phone number has the +63 prefix
                  String phoneNumber = numberController.text.trim();
                  if (!phoneNumber.startsWith('+63')) {
                    phoneNumber = '+63' +
                        phoneNumber.replaceAll(RegExp(r'\D'),
                            ''); // Add +63 and remove non-digit characters
                  }

                  if (existingContact != null) {
                    // Update an existing contact
                    int index = emergencyContacts.indexOf(existingContact);
                    onEdit(index, nameController.text,
                        phoneNumber); // Use the formatted number
                  } else {
                    // Add a new contact
                    setState(() {
                      emergencyContacts.add({
                        'name': nameController.text,
                        'number':
                            phoneNumber, // Add the formatted number with +63
                      });
                    });
                    _saveEmergencyContacts(); // Save changes locally and to Google Sheets
                  }
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                }
              },
              child: Text(existingContact != null ? 'Update' : 'Add'),
            )
          ],
        );
      },
    );
  }
}

class ContactCard extends StatelessWidget {
  final String name;
  final String number;
  final bool isEditing;
  final VoidCallback onDelete; // Callback to handle delete action
  final Function(String, String) onEdit; // Callback to handle edit action

  const ContactCard({
    super.key,
    required this.name,
    required this.number,
    required this.isEditing,
    required this.onDelete, // Add the callback to the constructor
    required this.onEdit, // Add the edit callback
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        title: Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          number, // Display the number with +63 prefix
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isEditing
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () {
                      _showEditDialog(context); // Open the edit dialog
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.error, color: Colors.red),
                    onPressed: () {
                      // Show confirmation dialog before deleting
                      _showDeleteConfirmationDialog(context);
                    },
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.phone, color: Constants.cyanColor),
                    onPressed: () {
                      _callContact(context);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.location_pin, color: Constants.cyanColor),
                    onPressed: () async {
                      // Send SMS to the selected contact's number
                      _sendSmsWithLocation(context);
                    },
                  ),
                ],
              ),
      ),
    );
  }

  // Function to show the delete confirmation dialog
  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirm Deletion',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          content: const Text('Are you sure you want to delete this contact?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel',
                  style: TextStyle(fontSize: 16, color: Constants.cyanColor)),
            ),
            TextButton(
              onPressed: () {
                onDelete(); // Call the delete callback
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Delete',
                  style: TextStyle(fontSize: 16, color: Constants.cyanColor)),
            ),
          ],
        );
      },
    );
  }

  // Function to show the edit dialog
  void _showEditDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController(text: name);

    // Remove the '+63' prefix temporarily when displaying the number
    String displayNumber =
        number.startsWith('+63') ? number.substring(3) : number;

    TextEditingController numberController = TextEditingController(
        text:
            displayNumber); // Set the controller with the number without the prefix

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                      20), // Limit to 20 characters
                ],
              ),
              TextField(
                controller: numberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixText: '(+63)', // Keep the prefix for display
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                      10), // Limit to 20 characters
                ],
                maxLength: 10, // Limit input to 10 digits
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String updatedName = nameController.text;
                String updatedNumber = numberController.text;

                // Validate phone number length
                if (updatedNumber.length != 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Phone number must be 10 digits')),
                  );
                  return; // Exit the function if validation fails
                }

                // Proceed with the edit if valid
                onEdit(updatedName,
                    '+63$updatedNumber'); // Re-add the +63 prefix when saving
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _sendSmsWithLocation(BuildContext context) async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    // If the location services are not enabled or permission is denied, prompt the user
    if (!serviceEnabled ||
        permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Prompt the user to enable location services
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Please turn on location services to share your location.'),
        ),
      );
      // You can also direct them to the location settings page if needed
      Geolocator.openLocationSettings();
      return; // Exit the function early if location services are not enabled
    }

    // Access userName from the DashboardState
    final dashboardState = context.findAncestorStateOfType<_DashboardState>();
    String userName =
        dashboardState?.userName ?? "Unknown User"; // Fallback if null

    // Construct the initial SMS body
    String smsText =
        "This is $userName, and currently I am in danger due to a disaster. My location is below. Please help!";

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      String locationDescription =
          'I am around this vicinity: Latitude: ${position.latitude}, Longitude: ${position.longitude}\n\nCopy and paste these coordinates in Google Maps to find my location: ${position.latitude}, ${position.longitude}\n\n- Sent via AlertMate.';
      smsText += '\n\nLocation description: $locationDescription';

      // Format the phone number (ensure it uses the correct format)
      String formattedPhoneNumber =
          number.replaceAll(RegExp(r'\s+'), '').replaceFirst('+63', '0');

      final Uri smsUri = Uri(
        scheme: 'sms',
        path: formattedPhoneNumber,
        queryParameters: {'body': smsText},
      );

      if (await canLaunch(smsUri.toString())) {
        await launch(smsUri.toString());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send SMS')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send SMS: $e')),
      );
    }
  }

  // Function to handle the call action
  void _callContact(BuildContext context) async {
    final Uri phoneUri =
        Uri(scheme: 'tel', path: number); // Create a URI with the phone number
    if (await canLaunch(phoneUri.toString())) {
      await launch(phoneUri.toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone dialer')),
      );
    }
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _password = ""; // Initially empty password
  String _currentPhone = ""; // To store the logged-in user's phone number

  @override
  void initState() {
    super.initState();
    _loadPassword(); // Load password when the page is loaded
  }

  void _loadPassword() async {
    final prefs = await SharedPreferences.getInstance();
    _currentPhone = prefs.getString('phone') ?? ""; // Correct key for phone

    if (_currentPhone.isEmpty) {
      print('Phone is empty'); // Debugging output
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No user is logged in!")),
      );
      return;
    }

    print('Current phone: $_currentPhone'); // Debugging output

    // Fetch password from Google Sheets
    final password = await UserSheetsApi.getPasswordByPhone(_currentPhone);

    if (password != null) {
      setState(() {
        _password = password; // Update the UI with the fetched password
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load password!")),
      );
    }
  }

  // Function to save the password to SharedPreferences
  void _savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', password); // Save the password
  }

  // Function to show dialog for editing the password
  void _changePassword(BuildContext context) {
    final TextEditingController _passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: TextField(
            controller: _passwordController,
            obscureText: true, // Hide text as user types
            decoration: const InputDecoration(
              labelText: 'Enter new password',
              hintText: 'Password',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog without saving
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newPassword = _passwordController.text;

                // Validate the new password
                if (newPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Password cannot be empty!")),
                  );
                  return;
                }

                // Try updating the password in Google Sheets
                try {
                  await UserSheetsApi.updatePasswordByPhone(
                    phone: _currentPhone, // Pass phone as a named parameter
                    newPassword: newPassword,
                  );

                  setState(() {
                    _password =
                        newPassword; // Update the UI with the new password
                  });
                  _savePassword(newPassword); // Save the new password locally
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Password updated successfully!")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update password!")),
                  );
                }

                Navigator.pop(context); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to logout the user by clearing credentials and navigating to LoginPage
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Remove stored credentials
    await prefs.remove('password');
    await prefs.setBool('isLoggedIn', false); // Update login state

    // Reset local state if necessary
    setState(() {
      _password = ""; // Clear password in the UI
    });

    // Navigate to LoginPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );

    // Show feedback to the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logged out successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Constants.bgColor,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Make the title bold
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Password',
              style: TextStyle(fontSize: 12, color: Constants.cyanColor),
            ),
            const SizedBox(height: 0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _password.isEmpty
                      ? '**********' // Show asterisks if no password is set
                      : '*' *
                          _password
                              .length, // Dynamically show asterisks based on the password length
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.edit), // Pencil icon
                  onPressed: () {
                    _changePassword(context); // Show dialog to change password
                  },
                ),
              ],
            ),
            const SizedBox(
                height: 24), // Add space between password and logout button
            TextButton(
              onPressed: _logout, // Call the logout function
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
