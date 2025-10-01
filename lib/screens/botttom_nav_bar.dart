import 'package:flutter/material.dart';

import 'MusicScreen.dart';

class BotttomNavBar extends StatefulWidget {
  const BotttomNavBar({super.key});

  @override
  State<BotttomNavBar> createState() => _BotttomNavBarState();
}

class _BotttomNavBarState extends State<BotttomNavBar> {

  final List<Widget> _screens = [
    const Songs(),
    const Text('Videos'),
    const Text('Favourites'),
    const Text('Account')
  ];

  int _currentScreenIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentScreenIndex],
      bottomNavigationBar: NavigationBar(destinations: [
        NavigationDestination(icon: Icon(Icons.music_note), label: 'Music',),
        NavigationDestination(icon: Icon(Icons.video_collection),label: 'Videos',),
        NavigationDestination(icon: Icon(Icons.star), label: 'Favourites'),
        NavigationDestination(icon: Icon(Icons.account_circle), label: 'Account')
      ],
        selectedIndex: _currentScreenIndex,
        backgroundColor: Colors.transparent,
        onDestinationSelected: (int newDestination){
        setState(() {
          _currentScreenIndex = newDestination;
        });
      },),
    );
  }
}
