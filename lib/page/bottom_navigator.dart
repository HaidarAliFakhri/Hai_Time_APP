import 'package:flutter/material.dart';
import 'package:hai_time_app/page/home_page.dart';
import 'package:hai_time_app/view/prayer_schedule_page.dart';
import 'package:hai_time_app/view/weather_page.dart';

class BottomNavigator extends StatefulWidget {
  //
  const BottomNavigator({super.key});

  @override
  State<BottomNavigator> createState() => _BottomNavigatorState();
}

class _BottomNavigatorState extends State<BottomNavigator> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      //  HomePage kirim callback ke Cuaca
      HomePage(
        onGoToWeather: () => _onItemTapped(2),
        
      ),
      //  JadwalPage
      JadwalPage(
        onBackToHome: () => _onItemTapped(0),
      ),
      //  CuacaPage
      CuacaPage(
        onBackToHome: () => _onItemTapped(0),
      ),
    ];
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            activeIcon: Icon(Icons.schedule),
            label: "Jadwal",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_outlined),
            activeIcon: Icon(Icons.cloud),
            label: "Cuaca",
          ),
        ],
      ),
    );
  }
}
