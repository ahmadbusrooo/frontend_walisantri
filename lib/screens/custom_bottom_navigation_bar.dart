import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; // Import screen terkait
import 'transaction_screen.dart';
import 'information_screen.dart';
import 'account_screen.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex; // Indeks halaman aktif

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex, // Wajib menentukan indeks
  }) : super(key: key);

  void _navigateToScreen(BuildContext context, int index) {
    if (currentIndex == index) return; // Hindari reload jika di halaman yang sama

    switch (index) {
      case 0: // Beranda
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
        break;
      case 1: // Transaksi
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TransactionScreen()),
        );
        break;
      case 2: // Informasi
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => InformationScreen()),
        );
        break;
      case 3: // Akun
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AccountScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex, // Menentukan halaman aktif
      onTap: (index) => _navigateToScreen(context, index), // Navigasi saat item diklik
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Transaksi'),
        BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Informasi'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
      ],
    );
  }
}
