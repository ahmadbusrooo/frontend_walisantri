import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_walisantri/services/api_service.dart';
import 'package:app_walisantri/models/transaction_model.dart';
import 'custom_bottom_navigation_bar.dart';
import 'transaction_detail_screen.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({Key? key}) : super(key: key);

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  late Future<TransactionResponse> _transactionFuture;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
 String? selectedPeriod;
  String selectedPaymentType = 'ALL';
  List<String> periods = [];
@override
void initState() {
  super.initState();
  _transactionFuture = _loadTransactions().then((value) {
    if (value.transactions.isNotEmpty) {
      setState(() {
        selectedPeriod = value.transactions.first.period;
      });
    }
    return value;
  });
}
Future<TransactionResponse> _loadTransactions() async {
  final response = await ApiService.fetchTransactionData();
  final transactionResponse = TransactionResponse.fromJson(response);
  
  // Ekstrak periode unik
  final periodSet = transactionResponse.transactions
      .map((t) => t.period)
      .toSet()
      .toList();
  periodSet.sort();
  
  if (mounted) {
    setState(() {
      periods = periodSet;
      selectedPeriod = periodSet.isNotEmpty ? periodSet.first : null;
    });
  }
  
  return transactionResponse;
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: FutureBuilder<TransactionResponse>(
        future: _transactionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          } else if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          } else if (!snapshot.hasData) {
            return _buildEmpty();
          }
          return _buildTransactionList(snapshot.data!);
        },
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.teal),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => _transactionFuture = _loadTransactions()),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Tidak ada transaksi',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600
            ),
          ),
        ],
      ),
    );
  }
Widget _buildFilterControls() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: _buildPeriodDropdown(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPaymentTypeDropdown(),
        ),
      ],
    ),
  );
}

Widget _buildPeriodDropdown() {
  return InputDecorator(
    decoration: InputDecoration(
      labelText: 'Periode',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedPeriod,
        isExpanded: true,
        items: periods.map((period) {
          return DropdownMenuItem(
            value: period,
            child: Text(period),
          );
        }).toList(),
        onChanged: (value) => setState(() => selectedPeriod = value),
        hint: const Text('Pilih Periode'),
      ),
    ),
  );
}

Widget _buildPaymentTypeDropdown() {
  return InputDecorator(
    decoration: InputDecoration(
      labelText: 'Jenis Pembayaran',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedPaymentType,
        isExpanded: true,
        items: const [
          DropdownMenuItem(value: 'ALL', child: Text('Semua Jenis')),
          DropdownMenuItem(value: 'BEBAS', child: Text('Bebas')),
          DropdownMenuItem(value: 'BULANAN', child: Text('Bulanan')),
        ],
        onChanged: (value) => setState(() => selectedPaymentType = value!),
      ),
    ),
  );
}


Widget _buildTransactionList(TransactionResponse data) {
  final filteredTransactions = data.transactions.where((transaction) {
    final periodMatch = selectedPeriod == null || 
        transaction.period == selectedPeriod;
    final paymentTypeMatch = selectedPaymentType == 'ALL' || 
        transaction.paymentType == selectedPaymentType;
    return periodMatch && paymentTypeMatch;
  }).toList();

  return Column(
    children: [
      const SizedBox(height: 20), // Tambahkan jarak antara AppBar dan Dropdown
      _buildFilterControls(),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filteredTransactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return TransactionItem(
              transaction: filteredTransactions[index],
            );
          },
        ),
      ),
    ],
  );
}


  Widget _buildSummaryRow(String label, int amount, {bool isBalance = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500
          ),
        ),
        Text(
          _currencyFormat.format(amount),
          style: TextStyle(
            color: isBalance ? Colors.amber.shade200 : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold
          ),
        ),
      ],
    );
  }
}

class TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionItem({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(
              transaction: transaction,
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildPaymentTypeIcon(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.paymentName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                transaction.formattedDate,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Detail Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'No. Kwitansi: ${transaction.details.receiptNumber}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    transaction.formattedAmount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              
              if (transaction.details.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    transaction.details.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTypeIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: transaction.paymentType == 'BULANAN'
            ? Colors.teal.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        transaction.paymentType == 'BULANAN'
            ? Icons.calendar_today
            : Icons.credit_card,
        color: transaction.paymentType == 'BULANAN'
            ? Colors.teal
            : Colors.blue,
        size: 20,
      ),
    );
  }

  Widget _buildStatusChip() {
    return Chip(
      backgroundColor: _getStatusColor(transaction.status).withAlpha(25),
      label: Text(
        transaction.status,
        style: TextStyle(
          color: _getStatusColor(transaction.status),
          fontWeight: FontWeight.bold,
        ),
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