import 'package:flutter/material.dart';

class InformationDetailScreen extends StatelessWidget {
  final String title;
  final String description;
  final String? imageUrl;
  final String date;

  InformationDetailScreen({
    required this.title,
    required this.description,
    this.imageUrl,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Informasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Colors.white, // Mengubah warna tombol back menjadi putih
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Informasi dengan padding dan rounded corners
            if (imageUrl != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16), // Rounded corners
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.contain, // Menampilkan ukuran asli gambar
                    width: double.infinity,
                  ),
                ),
              ),
            // Konten Informasi
            Padding(
              padding: const EdgeInsets.all(16.0), // Sama dengan padding gambar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    description.replaceAll(RegExp(r'<[^>]*>'), ''),
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
