import 'package:alertmate/constants.dart';
import 'package:alertmate/ui/home_page.dart';
import 'package:alertmate/ui/screens/alert_page.dart';
import 'package:alertmate/ui/screens/dashboard.dart';
import 'package:alertmate/ui/screens/location_page.dart';
import 'package:alertmate/ui/screens/news_page.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _HomePageState();
}

class _HomePageState extends State<RootPage> {
  int _bottomNavIndex = 0;
  bool _isHomePage = true; // Track if the HomePage is currently displayed

  // List of pages (excluding HomePage)
  List<Widget> pages = const [
    NewsPage(),
    LocationPage(),
    AlertPage(),
    Dashboard(),
  ];

  // List of page icons
  List<IconData> iconList = [
    Icons.article, // News
    Icons.location_on, // Location
    Icons.phone, // Alert
    Icons.person, // Dashboard
  ];

  // List of page titles
  List<String> titleList = [
    'News',
    'Location',
    'Alert',
    'Dashboard',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: _isHomePage
      //       ? null // No title for HomePage; the design will come from `home_page.dart`
      //       : Row(
      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //           children: [
      //             Text(
      //               titleList[_bottomNavIndex],
      //               style: TextStyle(
      //                 color: Constants.blackColor,
      //                 fontWeight: FontWeight.w500,
      //                 fontSize: 18,
      //               ),
      //             ),
      //           ],
      //         ),
      //   backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // ),
      body: _isHomePage
          ? const HomePage() // Show HomePage initially
          : IndexedStack(
              index: _bottomNavIndex,
              children: pages,
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: "rootPageFAB", // Ensure this is unique
        onPressed: () {
          setState(() {
            _isHomePage = true;
          });
        },
        backgroundColor: Colors.black.withOpacity(0),
        elevation: 0,
        shape: const CircleBorder(),
        child: ClipOval(
          child: Image.asset(
            _isHomePage ? 'assets/home logo 2.png' : 'assets/home logo.png',
            height: 85.0,
            fit: BoxFit.cover,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        splashColor: Constants.primaryColor,
        activeColor: Constants.cyanColor,
        inactiveColor: Colors.black.withOpacity(.5),
        activeIndex: _isHomePage
            ? -1
            : _bottomNavIndex, // Disable active icon on HomePage
        icons: iconList,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.softEdge,
        onTap: (index) {
          setState(() {
            _isHomePage = false; // Switch away from HomePage
            _bottomNavIndex = index;
          });
        },
      ),
    );
  }
}
