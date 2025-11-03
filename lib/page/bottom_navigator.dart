import 'package:flutter/material.dart';
import 'package:hai_time_app/page/home_page.dart';
import 'package:hai_time_app/view/cuaca.dart';
import 'package:hai_time_app/view/jadwal_page.dart';

class BottomNavigator extends StatefulWidget {
  const BottomNavigator({super.key});

  @override
  State<BottomNavigator> createState() => _BottomNavigatorState();
}

class _BottomNavigatorState extends State<BottomNavigator> {
  int _selectedIndex = 0;

  // ❗ Jangan langsung gunakan const list kalau ada parameter non-const
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // inisialisasi pages; kita kirim callback onBackToHome ke JadwalPage
    _pages = [
      const HomePage(),
      // Beri JadwalPage sebuah callback yang mengubah tab ke index 0
      JadwalPage(
        onBackToHome: () {
          setState(() {
            _selectedIndex = 0;
          });
        },
      ),
      CuacaPage(onBackToHome: () => _onItemTapped(0)), 
    ];
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // cegah rebuild jika sama
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        // gunakan key supaya AnimatedSwitcher tahu child berubah
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
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
      ),
    );
  }
}
