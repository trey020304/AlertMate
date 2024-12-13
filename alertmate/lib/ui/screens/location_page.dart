import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:alertmate/constants.dart';
import 'package:alertmate/model/route.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  LatLng? userLocation; // Initial location is null
  final List<Map<String, dynamic>> locations = [
    // Hospitals
    {
      "name": "Golden Gate Hospital",
      "location": LatLng(13.757849383475639, 121.06176983164929),
      "type": "Hospital",
    },
    {
      "name": "Batangas Regional Hospital",
      "location": LatLng(13.766775158704847, 121.06680113383266),
      "type": "Hospital",
    },
    {
      "name": "St Patricks Hospital Medical Center",
      "location": LatLng(13.75583664092928, 121.06024567727835),
      "type": "Hospital",
    },
    {
      "name": "Batangas Health Care Hospital Jesus Of Nazareth",
      "location": LatLng(13.759561325369946, 121.07696071454731),
      "type": "Hospital",
    },
    {
      "name": "United Doctors Of St. Camillus De Lellis Hospital",
      "location": LatLng(13.782151816347808, 121.0559514326206),
      "type": "Hospital",
    },
    {
      "name": "Batangas Healthcare Specialists Medical Center",
      "location": LatLng(13.78790552676346, 121.0602077533129),
      "type": "Hospital",
    },

    // Fire Stations
    {
      "name": "Batangas City Poblacion Fire Station",
      "location": LatLng(13.755849889478727, 121.05121215245627),
      "type": "Fire Station",
    },
    {
      "name": "Batangas City Alangilan Fire Station",
      "location": LatLng(13.791041425329002, 121.06748292050872),
      "type": "Fire Station",
    },
    {
      "name": "Batangas City Central Fire Station",
      "location": LatLng(13.776089636539714, 121.04446693754896),
      "type": "Fire Station",
    },

    // Police Stations
    {
      "name": "Batangas City Police Station",
      "location": LatLng(13.760149334771459, 121.058636435305),
      "type": "Police Station",
    },
    {
      "name": "Batangas PPO (Pres. Jose P. Laurel Highway, Camp Malvar)",
      "location": LatLng(13.77659497853149, 121.06642444573349),
      "type": "Police Station",
    },
    {
      "name": "Balagtas PAC (Diversion Road, Brgy. Balagtas)",
      "location": LatLng(13.797751309943013, 121.07085211367404),
      "type": "Police Station",
    },
  ];

  final Distance distance = Distance();
  final List<double> distancesToLocations =
      []; // Store distances for all locations
  List<List<LatLng>> polylinePoints =
      []; // Store polyline points for each location
  MapController mapController = MapController(); // Controller for the map
  List<Map<String, dynamic>> filteredMarkers =
      []; // List to store filtered markers
  String filterType = 'Hospitals'; // Track the current filter type
  bool isFiltered = false; // Track if a filter has been applied
  String nearestLocation = ''; // Store the name of the nearest location
  double nearestLocationDistance =
      0.0; // Store the distance to the nearest location
  bool isAltRoute =
      false; // Tracks whether to show the alt_route or location_pin icon
  Color buttonColor = Colors.grey; // Default color of the icon
  Color buttonBackgroundColor = Colors.white; // Default background color

  @override
  void initState() {
    super.initState();
    filteredMarkers = [];
    calculateDistances();
    fetchUserLocation();
  }

  Future<void> fetchUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
            "Location services are disabled. Enable them to use this feature.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          "Location permissions are permanently denied. Enable them from settings.",
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
      });

      calculateDistances();
    } catch (e) {
      print("Error fetching user location: $e");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Location Error"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    }
  }

  void calculateDistances() {
    if (userLocation == null) return;

    distancesToLocations.clear();
    polylinePoints.clear();
    List<Map<String, dynamic>> filteredLocations = locations
        .where((location) =>
            location["type"] == filterType || filterType == 'All Locations')
        .toList();

    for (var location in filteredLocations) {
      double distInMeters = distance.as(
        LengthUnit.Meter,
        userLocation!,
        location["location"],
      );
      double distInKm = double.parse((distInMeters / 1000).toStringAsFixed(2));
      distancesToLocations.add(distInKm);
    }

    if (distancesToLocations.isNotEmpty) {
      if (!isAltRoute) {
        // Fetch the nearest route if not in alt_route mode
        double minDistance =
            distancesToLocations.reduce((a, b) => a < b ? a : b);
        int nearestIndex = distancesToLocations.indexOf(minDistance);
        fetchRoute(userLocation!, filteredLocations[nearestIndex]["location"]);

        setState(() {
          nearestLocation = filteredLocations[nearestIndex]["name"];
          nearestLocationDistance = minDistance;
        });
      } else {
        // If alt_route is enabled, fetch routes for all locations
        for (var location in filteredLocations) {
          fetchRoute(userLocation!, location["location"]);
        }
      }
    }

    setState(() {});
  }

  Future<void> fetchRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car'
      '?start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization':
              openRouteServiceApiKey, // Use the API key from config
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> coordinates =
            data['features'][0]['geometry']['coordinates'];

        // Convert coordinates to LatLng and update polyline
        List<LatLng> routePoints =
            coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();

        // Log route fetching for debugging
        print('Fetched route from ${start.toString()} to ${end.toString()}');
        polylinePoints.add(routePoints);
        setState(() {}); // Assuming this is in a stateful widget
      } else {
        throw Exception('Failed to fetch route');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  void _openFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Locations',
            style: TextStyle(fontWeight: FontWeight.w500)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.local_hospital,
                  color: Constants.cyanColor, size: 40),
              title: const Text('Show Hospitals'),
              onTap: () {
                setState(() {
                  filterType = 'Hospital'; // Set the filter to Hospitals
                  filteredMarkers = locations
                      .where((marker) => marker["type"] == "Hospital")
                      .toList();
                  isFiltered = true; // Mark that a filter is applied
                });
                Navigator.of(context).pop();
                calculateDistances(); // Recalculate distances for filtered locations
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_fire_department,
                  color: Colors.orange, size: 40),
              title: const Text('Show Fire Stations'),
              onTap: () {
                setState(() {
                  filterType =
                      'Fire Station'; // Set the filter to Fire Stations
                  filteredMarkers = locations
                      .where((marker) => marker["type"] == "Fire Station")
                      .toList();
                  isFiltered = true; // Mark that a filter is applied
                });
                Navigator.of(context).pop();
                calculateDistances(); // Recalculate distances for filtered locations
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.local_police, color: Colors.blue, size: 40),
              title: const Text('Show Police Stations'),
              onTap: () {
                setState(() {
                  filterType =
                      'Police Station'; // Set the filter to Police Stations
                  filteredMarkers = locations
                      .where((marker) => marker["type"] == "Police Station")
                      .toList();
                  isFiltered = true; // Mark that a filter is applied
                });
                Navigator.of(context).pop();
                calculateDistances(); // Recalculate distances for filtered locations
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Function to center map back to the user's current location
  void _goToUserLocation() {
    mapController.move(userLocation!,
        18.0); // Move the map to the user's location with zoom level 16
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Location',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    center: userLocation,
                    zoom: 18.0,
                    maxZoom: 18.4,
                    minZoom: 10.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                      additionalOptions: {
                        'attribution': '© OpenStreetMap contributors',
                      },
                    ),
                    if (isFiltered) ...[
                      // PolylineLayer comes first so that it's rendered behind markers
                      PolylineLayer(
                        polylines: polylinePoints
                            .map(
                              (points) => Polyline(
                                points: points,
                                strokeWidth: 4.0,
                                color: isAltRoute
                                    ? const Color.fromARGB(255, 10, 139, 139)
                                    : const Color.fromARGB(255, 10, 139,
                                        139), // Differentiate polylines if needed
                              ),
                            )
                            .toList(),
                      ),
                      MarkerLayer(
                        markers: [
                          // User's current location marker
                          Marker(
                            point: userLocation!,
                            builder: (context) => Icon(
                              Icons.location_on, // Icon for user's location
                              color: Constants
                                  .cyanColor, // Color for the icon (can be customized)
                              size: 45.0, // Size of the icon
                            ),
                          ),
                          ...filteredMarkers.map((marker) {
                            IconData icon;
                            Color color;

                            // Set icon and color based on marker type
                            switch (marker["type"]) {
                              case "Hospital":
                                icon = Icons.local_hospital;
                                color = Constants.cyanColor;
                                break;
                              case "Fire Station":
                                icon = Icons.local_fire_department;
                                color = Colors.orange;
                                break;
                              case "Police Station":
                                icon = Icons.local_police;
                                color = Colors.blue;
                                break;
                              default:
                                icon = Icons.location_on;
                                color = Colors.black;
                                break;
                            }

                            return Marker(
                              point: marker["location"],
                              builder: (context) => Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Large white circle with a grey shadow
                                  Container(
                                    width: 60.0, // Circle size
                                    height: 60.0, // Circle size
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors
                                            .white, // Optional: outline for visibility
                                        width: 2.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(
                                              0.5), // Grey shadow color with some opacity
                                          spreadRadius:
                                              2.0, // Spread the shadow outwards
                                          blurRadius:
                                              5.0, // Blur the shadow for softness
                                          offset: Offset(3,
                                              3), // Shadow offset (down and to the right)
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Icon in the center of the circle
                                  Icon(
                                    icon,
                                    color: color,
                                    size: 25.0, // Icon size
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      )
                    ],
                  ],
                ),
                // Location List and Distances Floating at the Top
                if (isFiltered)
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        title: Text(
                          '$filterType and Distances',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        children: [
                          SizedBox(
                            height: 400,
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredMarkers.length,
                              itemBuilder: (context, i) {
                                return ListTile(
                                  title: Text(filteredMarkers[i]["name"]),
                                  subtitle: Text(
                                    "Location: ${filteredMarkers[i]["location"].latitude.toStringAsFixed(4)}, "
                                    "${filteredMarkers[i]["location"].longitude.toStringAsFixed(4)}\n"
                                    "Distance: ${distancesToLocations.isNotEmpty ? distancesToLocations[i].toString() : 'Calculating...'} km",
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Add this new Positioned widget for the building button
                Positioned(
                  bottom: 150, // Position above the filter button
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        isAltRoute = !isAltRoute; // Toggle between the icons
                        buttonColor = isAltRoute
                            ? Colors.white
                            : Colors.grey; // Toggle color
                        buttonBackgroundColor = isAltRoute
                            ? Constants.cyanColor
                            : Colors.white; // Toggle background color
                      });
                      calculateDistances(); // Recalculate distances and routes based on mode
                    },
                    backgroundColor: buttonBackgroundColor,
                    shape: const CircleBorder(),
                    child: Icon(
                      isAltRoute
                          ? Icons.alt_route
                          : Icons.location_pin, // Toggle icons
                      color: buttonColor, // Use the toggled color
                    ),
                  ),
                ),
                // Filter button positioned above the goToUserLocation button
                Positioned(
                  bottom: 85, // Position it above the goToUserLocation button
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: _openFilter, // Opens the filter functionality
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    child: const Icon(
                      Icons.near_me_outlined,
                      color: Colors.grey,
                    ),
                  ),
                ),
                // Floating action button to return to user location with a circular shape
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: _goToUserLocation,
                    backgroundColor: Constants.cyanColor,
                    shape: const CircleBorder(),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Floating widget displaying nearest location, below the filter button
                if (nearestLocation.isNotEmpty) ...[
                  Positioned(
                    bottom:
                        35, // Position it just above the Go to User Location button
                    left: 20,
                    child: Center(
                      child: Material(
                        elevation: 5.0,
                        borderRadius: BorderRadius.circular(
                            10), // Increased border radius
                        child: SizedBox(
                          width: 285, // Set desired width here
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(10), // Same radius here
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Nearest Recommended Location:",
                                  style: TextStyle(
                                    color: Constants.cyanColor,
                                  ),
                                ),
                                Text(
                                  '$nearestLocation ($nearestLocationDistance km)',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
