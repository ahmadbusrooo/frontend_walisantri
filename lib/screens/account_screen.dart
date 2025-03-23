import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';
import '../utils/shared_preferences_helper.dart';
import 'custom_bottom_navigation_bar.dart';
import 'profile_detail_screen.dart'; // Import halaman detail profil

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final response = await ApiService.fetchStudentData();
      setState(() {
        profileData = response['data']; // Ambil bagian 'data' dari respons
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching profile data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Akun',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  SizedBox(height: 20),
                  _buildListTile(
                    icon: Icons.lock_outline,
                    text: "Ganti password",
                    onTap: () {
                      // Ganti password logic
                    },
                  ),
                  Divider(),
                  _buildListTile(
                    icon: Icons.file_copy_outlined,
                    text: "Syarat dan Ketentuan",
                    onTap: () {
                      // Navigasi ke halaman syarat dan ketentuan
                    },
                  ),
                  Divider(),
                  _buildListTile(
                    icon: Icons.privacy_tip_outlined,
                    text: "Kebijakan Privasi",
                    onTap: () {
                      // Navigasi ke halaman kebijakan privasi
                    },
                  ),
                  Divider(),
                  _buildLogoutTile(context),
                  SizedBox(height: 40),
                  _buildSocialMediaIcons(),
                  SizedBox(height: 20),
                ],
              ),
            ),
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 3),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(
              profileData != null && profileData!['student_img'] != null
                  ? "http://172.20.10.3/uploads/student/${profileData!['student_img']}"
                  : "https://via.placeholder.com/150",
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profileData?['student_full_name'] ?? "Nama Tidak Tersedia",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "NIS: ${profileData?['student_nis'] ?? "NIS Tidak Tersedia"}",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  profileData?['class_name'] ?? "Kelas Tidak Tersedia",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    if (profileData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfileDetailScreen(profileData: profileData!),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Data profil tidak tersedia'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(
                    "Lihat profil",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildLogoutTile(BuildContext mainContext) {
    return ListTile(
      leading: Icon(Icons.logout, color: Colors.red),
      title: Text(
        "Keluar akun",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () async {
        showModalBottomSheet(
          context: mainContext,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (BuildContext context) {
            return Container(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.exit_to_app, size: 50, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    "Keluar Akun",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Apakah Anda yakin ingin keluar dari akun Anda?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "Batal",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          try {
                            await ApiService.logout();
                            await SharedPreferencesHelper.clear();

                            Fluttertoast.showToast(
                              msg: "Berhasil logout",
                              backgroundColor: Colors.green,
                            );

                            Navigator.of(mainContext).pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            );
                          } catch (e) {
                            Fluttertoast.showToast(
                              msg: "Gagal logout: $e",
                              backgroundColor: Colors.red,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 17),
                        ),
                        child: Text(
                          "Keluar",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSocialMediaIcons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSocialMediaIcon(Icons.language, Colors.teal),
          _buildSocialMediaIcon(Icons.facebook, Colors.blue),
          _buildSocialMediaIcon(Icons.play_circle_fill, Colors.red),
        ],
      ),
    );
  }

  Widget _buildSocialMediaIcon(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}
