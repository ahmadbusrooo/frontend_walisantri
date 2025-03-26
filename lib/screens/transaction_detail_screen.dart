import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../models/transaction_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Detail Transaksi',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF2C3E50)),
            onPressed: () => _shareReceipt(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusHeader(context),
            _buildReceiptCard(context),
            _buildShadowDivider(),
            _buildDetailSections(context),
            _buildActionButton(context),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        children: [
          _buildStatusIndicator(),
          const SizedBox(height: 12),
          Text(
            transaction.status,
            style: TextStyle(
              color: _getStatusColor(transaction.status),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _getStatusMessage(transaction.status),
            style: const TextStyle(
              color: Color(0xFF7F8C8D),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStatusColor(transaction.status).withOpacity(0.1),
          ),
        ),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStatusColor(transaction.status).withOpacity(0.2),
          ),
        ),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStatusColor(transaction.status),
          ),
          child: Icon(
            _getStatusIcon(transaction.status),
            color: Colors.white,
            size: 30,
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAmountSection(),
          _buildDottedDivider(),
          _buildBankSection(),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
      child: Column(
        children: [
          const Text(
            'Total Pembayaran',
            style: TextStyle(
              color: Color(0xFF7F8C8D),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            transaction.formattedAmount,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(transaction.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined, 
                  size: 16, 
                  color: _getStatusColor(transaction.status)
                ),
                const SizedBox(width: 6),
                Text(
                  transaction.formattedDate,
                  style: TextStyle(
                    color: _getStatusColor(transaction.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDottedDivider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(
          30,
          (index) => Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: const Color(0xFFECF0F1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_outlined,
              color: Color(0xFF3498DB),
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.paymentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  transaction.paymentType,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_outlined,
              color: Color(0xFF3498DB),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShadowDivider() {
    return Container(
      height: 20,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.04),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSections(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildDetailCard(
            'Informasi Transaksi',
            Icons.receipt_long_outlined,
            [
              _buildDetailRow('Jenis Pembayaran', transaction.paymentName),
              _buildDetailRow('Tipe Pembayaran', transaction.paymentType),
              _buildDetailRow('Nominal', transaction.formattedAmount),
              _buildDetailRow('Tanggal', transaction.formattedDate),
              _buildDetailRow('Nomor Kwitansi', transaction.details.receiptNumber),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            'Detail Pembayaran',
            Icons.description_outlined,
            [
              if (transaction.details.description.isNotEmpty)
                _buildDetailRow('Deskripsi', transaction.details.description),
              if (transaction.details.month != null)
                _buildDetailRow('Bulan', transaction.details.month!),
              _buildDetailRow('Periode', transaction.period),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3498DB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF3498DB),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7F8C8D),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2C3E50),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ElevatedButton(
        onPressed: () => _downloadReceipt(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3498DB),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_outlined, size: 20),
            SizedBox(width: 8),
            Text(
              'Unduh Bukti Transaksi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DIBAYAR':
        return const Color(0xFF2ECC71);
      case 'INSTALLMENT':
        return const Color(0xFFE67E22);
      case 'PENDING':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'DIBAYAR':
        return Icons.check;
      case 'INSTALLMENT':
        return Icons.access_time;
      case 'PENDING':
        return Icons.hourglass_empty;
      default:
        return Icons.info;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'DIBAYAR':
        return 'Transaksi berhasil';
      case 'INSTALLMENT':
        return 'Pembayaran cicilan berhasil';
      case 'PENDING':
        return 'Menunggu konfirmasi';
      default:
        return 'Status tidak diketahui';
    }
  }
  

  // Metode untuk membuat dan mengunduh bukti transaksi PDF
 Future<void> _downloadReceipt(BuildContext context) async {
  try {
    _showLoadingDialog(context);
    
    final File? pdfFile = await _generateReceiptPdf();
    
    Navigator.of(context).pop();

    if (pdfFile == null) {
      // Tampilkan pesan jika user cancel
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penyimpanan dibatalkan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _showSuccessDialog(context, pdfFile);
    
  } catch (e) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal mengunduh: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  // Metode untuk berbagi bukti transaksi
  Future<void> _shareReceipt(BuildContext context) async {
  try {
    _showLoadingDialog(context);
    
    final File? pdfFile = await _generateReceiptPdf();
    
    Navigator.of(context).pop();

    if (pdfFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembuatan PDF dibatalkan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      text: 'Bukti Transaksi - ${transaction.details.receiptNumber}',
    );
    
  } catch (e) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal berbagi: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  // Membuat PDF untuk bukti transaksi
 Future<File?> _generateReceiptPdf() async {
    try {
    WidgetsFlutterBinding.ensureInitialized();
    final pdf = pw.Document();
    // Mendapatkan font dari asset
    final font = await rootBundle.load("assets/fonts/Poppins-Regular.ttf");
    final fontBold = await rootBundle.load("assets/fonts/Poppins-Bold.ttf");
    final ttf = pw.Font.ttf(font);
    final ttfBold = pw.Font.ttf(fontBold);
    
    // Menambahkan halaman ke PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'BUKTI TRANSAKSI',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 18,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        transaction.details.receiptNumber,
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: pw.BoxDecoration(
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                          color: PdfColor.fromHex('#F1F5F9'),
                        ),
                        child: pw.Text(
                          transaction.formattedAmount,
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: pw.BoxDecoration(
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                          color: _getPdfStatusColor(transaction.status),
                        ),
                        child: pw.Text(
                          transaction.status,
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Informasi Transaksi
                pw.Text(
                  'Informasi Transaksi',
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 14,
                  ),
                ),
                pw.Divider(),
                _buildPdfDetailRow('Jenis Pembayaran', transaction.paymentName, ttf),
                _buildPdfDetailRow('Tipe Pembayaran', transaction.paymentType, ttf),
                _buildPdfDetailRow('Nominal', transaction.formattedAmount, ttf),
                _buildPdfDetailRow('Tanggal', transaction.formattedDate, ttf),
                _buildPdfDetailRow('Nomor Kwitansi', transaction.details.receiptNumber, ttf),
                
                pw.SizedBox(height: 20),
                
                // Detail Pembayaran
                pw.Text(
                  'Detail Pembayaran',
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 14,
                  ),
                ),
                pw.Divider(),
                if (transaction.details.description.isNotEmpty)
                  _buildPdfDetailRow('Deskripsi', transaction.details.description, ttf),
                if (transaction.details.month != null)
                  _buildPdfDetailRow('Bulan', transaction.details.month!, ttf),
                _buildPdfDetailRow('Periode', transaction.period, ttf),
                
                pw.Spacer(),
                
                // Footer
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Terima kasih atas pembayaran Anda',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Dokumen ini dicetak secara otomatis dan sah tanpa tanda tangan',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 8,
                          color: PdfColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    
    // Simpan PDF ke penyimpanan sementara
 final bytes = await pdf.save();

    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan Bukti Transaksi',
      fileName: 'Bukti_Transaksi_${transaction.details.receiptNumber}.pdf',
      allowedExtensions: ['pdf'],
      type: FileType.custom,
      bytes: bytes,
    );
    if (outputPath == null) return null;

    // Tambahkan ekstensi .pdf jika belum ada
    if (!outputPath.endsWith('.pdf')) {
      outputPath += '.pdf';
    }

    
    return File(outputPath);
    
  } catch (e) {
    throw Exception("Gagal membuat PDF: ${e.toString()}");
  }
}

  // Helper untuk membuat baris detail dalam PDF
  pw.Widget _buildPdfDetailRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // Konversi warna status untuk PDF
  PdfColor _getPdfStatusColor(String status) {
    switch (status) {
      case 'DIBAYAR':
        return PdfColor.fromHex('#2ECC71');
      case 'INSTALLMENT':
        return PdfColor.fromHex('#E67E22');
      case 'PENDING':
        return PdfColor.fromHex('#E74C3C');
      default:
        return PdfColor.fromHex('#95A5A6');
    }
  }

  // Dialog loading
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3498DB)),
                ),
                SizedBox(height: 20),
                Text(
                  'Menyiapkan bukti transaksi...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Dialog sukses
 void _showSuccessDialog(BuildContext context, File? file) {
  if (file == null) return;
   final filePath = file.path.replaceAll('/storage/ermulated', '/storage/emulated');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2ECC71),
                  size: 60,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bukti Transaksi Berhasil Diunduh',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                 'File tersimpan di ${filePath}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF95A5A6),
                      ),
                      child: const Text('Tutup'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await Share.shareXFiles(
                          [XFile(file.path)],
                          text: 'Bukti Transaksi - ${transaction.details.receiptNumber}',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3498DB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Selesai',
                       style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}