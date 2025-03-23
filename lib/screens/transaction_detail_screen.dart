import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard(
              icon: Icons.receipt,
              title: 'Informasi Transaksi',
              children: [
                _buildDetailRow('Jenis Pembayaran', transaction.paymentName),
                _buildDetailRow('Tipe Pembayaran', transaction.paymentType),
                _buildDetailRow('Status', transaction.status,
                    valueColor: _getStatusColor(transaction.status)),
                _buildDetailRow('Tanggal', transaction.formattedDate),
                _buildDetailRow('Nominal', transaction.formattedAmount),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildDetailCard(
              icon: Icons.description,
              title: 'Detail Pembayaran',
              children: [
                _buildDetailRow('Nomor Kwitansi', transaction.details.receiptNumber),
                if (transaction.details.description.isNotEmpty)
                  _buildDetailRow('Deskripsi', transaction.details.description),
                if (transaction.details.month != null)
                  _buildDetailRow('Bulan', transaction.details.month!),
                _buildDetailRow('Periode', transaction.period),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DIBAYAR':
        return Colors.green;
      case 'INSTALLMENT':
        return Colors.orange;
      case 'PENDING':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}