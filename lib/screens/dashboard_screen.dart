import 'package:flutter/material.dart';
import 'violation_screen.dart';
import 'health_screen.dart';
import 'nadzhaman_screen.dart';
import 'payment_screen.dart';
import 'notification_screen.dart';
import 'izin_screen.dart';
import 'kitablist_screen.dart';
import '../services/api_service.dart';
import 'custom_bottom_navigation_bar.dart';
import 'information_detail_screen.dart'; // Import layar detail informasi
import 'information_screen.dart';
import 'package:intl/intl.dart';
import '../services/connectivity_service.dart';
import '../utils/shared_preferences_helper.dart';
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? dashboardData;
  Map<String, dynamic>? _cachedData;
  bool isLoading = true;
  int unreadNotifications = 3; // Contoh jumlah notifikasi yang belum dibaca
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  String getGreeting() {
    // Ambil waktu UTC sekarang dan konversi ke WIB (UTC+7)
    DateTime now = DateTime.now().toUtc().add(Duration(hours: 7));
    int hour = now.hour;

    if (hour >= 5 && hour < 10) {
      return 'Selamat Pagi,';
    } else if (hour >= 10 && hour < 15) {
      return 'Selamat Siang,';
    } else if (hour >= 15 && hour < 19) {
      return 'Selamat Sore,';
    } else {
      return 'Selamat Malam,';
    }
  }

  String _shortenText(String text, {int maxLength = 50}) {
    if (text.length > maxLength) {
      return text.substring(0, maxLength) + '...';
    }
    return text;
  }

  Future<void> _fetchDashboardData() async {
  setState(() => isLoading = true);
  try {
    final isConnected = await ConnectivityService.isConnected();
    
    if (isConnected) {
      // JIKA ONLINE: AMBIL DATA BARU DARI API
      final data = await ApiService.fetchDashboardData();
      _cachedData = data['data']; // SIMPAN KE CACHE
      await SharedPreferencesHelper.saveDashboardData(jsonEncode(data['data']));
    } else {
      // JIKA OFFLINE: COBA AMBIL DARI CACHE
      final cachedData = await SharedPreferencesHelper.getDashboardData();
      if (cachedData != null) {
        _cachedData = jsonDecode(cachedData);
      }
    }

    setState(() {
      dashboardData = _cachedData;
      isLoading = false;
      _isOffline = !isConnected;
    });

  } catch (e) {
    // JIKA GAGAL, GUNAKAN DATA CACHE TERAKHIR
    final cachedData = await SharedPreferencesHelper.getDashboardData();
    setState(() {
      dashboardData = cachedData != null ? jsonDecode(cachedData) : null;
      isLoading = false;
      _isOffline = true;
    });
  }
}

  String formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    final formatter = NumberFormat("#,##0", "id_ID");
    return formatter.format(amount);
  }

  void _showComingSoon() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.teal.withOpacity(0.3), Colors.teal],
                  ),
                ),
                child: Icon(Icons.construction, size: 60, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                "Fitur Belum Tersedia",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Fitur ini sedang dalam pengembangan. Nantikan update selanjutnya!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "Tutup",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
         onRefresh: () async {
    // TETAP IJINKAN REFRESH MESKI OFFLINE
    await _fetchDashboardData();
    if (_isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Anda Sedang Ofline, Silahkan Cek Koneksi Internet, Dan Refresh Kembali Halaman Ini'),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Section dengan ikon notifikasi
                    Container(
                      padding: EdgeInsets.fromLTRB(40, 70, 20, 30),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade600, Colors.teal.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        image: DecorationImage(
                          image: AssetImage('assets/icon/logoaula.png'),
                          alignment: Alignment(1, 1),
                          fit: BoxFit.contain,
                          opacity: 0.06,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                getGreeting(), // Ganti "Selamat Datang" dengan ini
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Stack(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.notifications,
                                        color: Colors.white, size: 28),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                NotificationScreen()),
                                      );
                                    },
                                  ),
                                  if (unreadNotifications > 0)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          '$unreadNotifications',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Walisantri',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            18, // Ukuran lebih kecil dari nama
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _shortenText(
                                        dashboardData?['student_full_name'] ??
                                            'Nama Tidak Tersedia',
                                        maxLength:
                                            15, // Tambahkan parameter ini
                                      ),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "NIS : ${dashboardData?['student_nis'] ?? "Tidak Tersedia"}",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 17,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Kelas : ${dashboardData?['class_name'] ?? "Tidak Tersedia"}",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white70,
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 44,
                                  backgroundImage: dashboardData != null &&
                                          dashboardData!['student_img'] != null
                                      ? NetworkImage(
                                          "${ApiService.baseUrl.replaceAll('/api', '')}/uploads/student/${dashboardData!['student_img']}",
                                        )
                                      : null,
                                  child: dashboardData == null ||
                                          dashboardData!['student_img'] == null
                                      ? Icon(Icons.person,
                                          size: 40, color: Colors.white)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

    AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: _isOffline ? 50 : 0,
      color: Colors.red,
      child: Center(
        child: Text(
          'Anda sedang offline. Data mungkin tidak terupdate.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    ),
 SizedBox(height: 20),
                    // Saldo Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.account_balance_wallet,
                                  color: Colors.teal, size: 40),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Tagihan',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Rp. ${formatCurrency(dashboardData?['total_tagihan'])}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: (_showComingSoon),
                                label: Text('Bayar'),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  textStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    // Menu Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          _buildMenuItem(Icons.payment, 'Tagihan', () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PaymentScreen()));
                          }),
                          _buildMenuItem(Icons.book, 'Hafalan', () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => NadzhamanScreen()),
                            );
                          }),
                          _buildMenuItem(Icons.menu_book, "Kitab", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => KitablistScreen()),
                            );
                          }),
                          _buildMenuItem(Icons.bed, 'Izin Pulang', () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => IzinScreen()),
                            );
                          }),
                          _buildMenuItem(Icons.people, 'Pelanggaran', () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ViolationScreen()),
                            );
                          }),
                          _buildMenuItem(Icons.medical_services, 'Rekam Medis',
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HealthScreen()),
                            );
                          }),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    // Informasi Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Informasi:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              if ((dashboardData?['information']?.length ?? 0) >
                                  3)
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            InformationScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Lihat Semua',
                                    style: TextStyle(
                                      color: Colors.teal,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (dashboardData != null &&
                              dashboardData!['information'] != null)
                            Column(
  children: [
    if (_isOffline && dashboardData == null)
      Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.wifi_off, size: 50, color: Colors.grey),
              Text('Tidak dapat memuat data\nSambungkan ke internet',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      )
    else if (dashboardData != null && dashboardData!['information'] != null)
      Column(
        children: [
                                ...List.generate(
                                  dashboardData!['information'].length > 3
                                      ? 3
                                      : dashboardData!['information'].length,
                                  (index) {
                                    final info =
                                        dashboardData!['information'][index];
                                    return Card(
                                      margin:
                                          EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 4,
                                      child: ListTile(
                                        leading: info['information_img'] != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  "${ApiService.baseUrl.replaceAll('/api', '')}/uploads/information/${info['information_img']}",
                                                  width: 70,
                                                  height: 70,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Icon(Icons.info,
                                                size: 50, color: Colors.teal),
                                        title: Text(
                                          info['information_title'] ??
                                              'Judul Tidak Tersedia',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        subtitle: Text(
                                          _shortenText(
                                            info['information_desc']
                                                    ?.replaceAll(
                                                        RegExp(r'<[^>]*>'),
                                                        '') ??
                                                'Deskripsi tidak tersedia',
                                          ),
                                          style: TextStyle(
                                              color: Colors.grey[700]),
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  InformationDetailScreen(
                                                title:
                                                    info['information_title'] ??
                                                        'Judul Tidak Tersedia',
                                                description: info[
                                                        'information_desc'] ??
                                                    'Deskripsi tidak tersedia',
                                                imageUrl: info[
                                                            'information_img'] !=
                                                        null
                                                    ? "${ApiService.baseUrl.replaceAll('/api', '')}/uploads/information/${info['information_img']}"
                                                    : null,
                                                date: info[
                                                        'information_input_date'] ??
                                                    'Tanggal tidak tersedia',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                                if ((dashboardData?['information']?.length ??
                                        0) >
                                    3)
                                  Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal[50],
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  InformationScreen(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Lihat Lebih Banyak',
                                          style: TextStyle(
                                            color: Colors.teal[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                        ],
                      )
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar:
          CustomBottomNavigationBar(currentIndex: 0), // Custom Navigator
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade100, Colors.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
