import 'package:flutter/material.dart';

class ProfileDetailScreen extends StatelessWidget {
  final Map<String, dynamic> profileData;

  ProfileDetailScreen({required this.profileData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 600;
          return Column(
            children: [
              _buildHeader(context, isWideScreen),
              SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCardSection(
                        title: "Data Pribadi Santri",
                        children: [
                          _buildInfoRow("NIS", profileData['student_nis']),
                          _buildInfoRow("NISN", profileData['student_nisn']),
                          _buildInfoRow(
                            "Jenis Kelamin",
                            profileData['student_gender'] == "L"
                                ? "Laki-laki"
                                : "Perempuan",
                          ),
                          _buildInfoRow("Komplek", profileData['majors_name']),
                          _buildInfoRow("Kamar", profileData['majors_short_name']),
                          _buildInfoRow("No. Telepon", profileData['student_phone']),
                          _buildInfoRow("Hobi", profileData['student_hobby']),
                          _buildInfoRow("Alamat", profileData['student_address']),
                          _buildInfoRow(
                            "Tempat Lahir",
                            profileData['student_born_place'],
                          ),
                          _buildInfoRow("Tanggal Lahir", profileData['student_born_date']),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildCardSection(
                        title: "Data Orang Tua Santri",
                        children: [
                          _buildInfoRow("Nama Ayah", profileData['student_name_of_father']),
                          _buildInfoRow("Nama Ibu", profileData['student_name_of_mother']),
                          _buildInfoRow("No. Telepon", profileData['student_parent_phone']),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isWideScreen) {
    return Container(
      padding: isWideScreen
          ? EdgeInsets.symmetric(horizontal: 40, vertical: 20)
          : EdgeInsets.fromLTRB(16, 40, 16, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(290),
        ),
        image: DecorationImage(
          image: AssetImage('assets/icon/logoaula.png'),
          alignment: Alignment(1, 1),
          fit: BoxFit.contain,
          opacity: 0.06,
        ),
      ),
      child: Column(
        crossAxisAlignment: isWideScreen ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              Text(
                'Detail Profil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isWideScreen ? 10 : 20),
          Row(
            mainAxisAlignment: isWideScreen ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isWideScreen ? 60 : 50,
                backgroundImage: NetworkImage(
                  profileData['student_img'] != null
                      ? "http://172.20.10.3/uploads/student/${profileData['student_img']}"
                      : "https://via.placeholder.com/150",
                ),
              ),
              SizedBox(width: isWideScreen ? 24 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profileData['student_full_name'] ?? "Nama Tidak Tersedia",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isWideScreen ? 24 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "NIS: ${profileData['student_nis'] ?? "Tidak Tersedia"}",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isWideScreen ? 18 : 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Kelas: ${profileData['class_name'] ?? "Tidak Tersedia"}",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isWideScreen ? 18 : 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required List<Widget> children,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.all(isWideScreen ? 24 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isWideScreen ? 24 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isWideScreen ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
              SizedBox(height: 16),
              ...children,
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? "Tidak Tersedia",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
