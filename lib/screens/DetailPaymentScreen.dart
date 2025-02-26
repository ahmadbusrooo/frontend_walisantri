import 'package:flutter/material.dart';

class DetailPaymentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Ambil data dari argument
    final Map<String, dynamic>? paymentData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (paymentData == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Detail Pembayaran")),
        body: Center(child: Text("Tidak ada data pembayaran.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Detail Pembayaran")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("👤 Nama Santri: ${paymentData['student_name']}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("📅 Bulan: ${paymentData['month_name']}"),
            Text("💰 Jumlah: Rp ${paymentData['amount']}"),
            Text("🗓 Tanggal Bayar: ${paymentData['payment_date']}"),
            Text("📝 Jenis Pembayaran: ${paymentData['payment_type']}"),
            Text("📆 Tahun Ajaran: ${paymentData['period']}"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Kembali ke halaman sebelumnya
              },
              child: Text("Tutup"),
            ),
          ],
        ),
      ),
    );
  }
}
