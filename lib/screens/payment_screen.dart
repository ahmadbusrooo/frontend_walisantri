import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

String formatTanggal(String? tanggal) {
  if (tanggal == null || tanggal.isEmpty) return '-';
  try {
    DateTime parsedDate = DateTime.parse(tanggal.trim());
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(parsedDate);
  } catch (e) {
    print("Error parsing date: $e");
    return 'Format tidak valid';
  }
}

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = true;
  List<dynamic> _periods = [];
  List<dynamic> _monthlyPayments = [];
  List<dynamic> _freePayments = [];
  String? _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _fetchPaymentData();
  }

  Future<void> _fetchPaymentData() async {
    try {
      final response = await ApiService.fetchPaymentData();
      if (response['status']) {
        setState(() {
          // Menyiapkan data periode
          _periods = response['data'].map((period) {
            return {
              'period_id': period['period']['period_id'],
              'period_start': period['period']['period_start'],
              'period_end': period['period']['period_end'],
              'status': period['period']['status'],
            };
          }).toList();

          // Cari tahun aktif
          final activePeriod = _periods.firstWhere(
            (period) => period['status'] == "1",
            orElse: () => null, // Jika tidak ada tahun aktif
          );

          // Setel tahun aktif sebagai pilihan default
          _selectedPeriod = activePeriod?['period_id'];

          // Menyiapkan pembayaran bulanan secara manual
          _monthlyPayments = [];
          response['data'].forEach((period) {
            final bulanDetails = period['payments']['bulan']['details'] ?? [];
            bulanDetails.forEach((detail) {
              detail['period_id'] = period['period']['period_id'];
              _monthlyPayments.add(detail);
            });
          });

          // Menyiapkan pembayaran bebas secara manual
          _freePayments = [];
          response['data'].forEach((period) {
            final bebasDetails = period['payments']['bebas']['details'] ?? [];
            bebasDetails.forEach((detail) {
              _freePayments.add({
                ...detail,
                'period_id': period['period']['period_id'].toString(),
                'bill': int.parse(detail['bill'].toString()),
                'total_pay': int.parse(detail['total_pay'].toString()),
              });
            });
          });

          _isLoading = false;
        });
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  List<dynamic> _filterDataByPeriod(List<dynamic> data, String? periodId) {
    if (periodId == null || periodId.isEmpty) return data;
    return data.where((payment) {
      return payment['period_id'].toString() == periodId.toString();
    }).toList();
  }

  void _showPeriodSelector() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 255, 255, 255),
                const Color.fromARGB(255, 255, 255, 255)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 40, 51, 50),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Pilih Tahun Ajaran',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 45, 47, 47),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _periods.length,
                  itemBuilder: (context, index) {
                    final period = _periods[index];
                    final isSelected = _selectedPeriod == period['period_id'];
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      tileColor: isSelected ? Colors.teal.shade100 : null,
                      leading: CircleAvatar(
                        backgroundColor:
                            isSelected ? Colors.teal : Colors.teal.shade100,
                        child: Icon(Icons.calendar_today, color: Colors.white),
                      ),
                      title: Text(
                        '${period['period_start']} - ${period['period_end']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.teal.shade900
                              : Colors.black87,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Colors.teal)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedPeriod = period['period_id'];
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentDetails(dynamic payment, bool isMonthly) {
    final numberFormat = NumberFormat.decimalPattern('id');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Judul
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    payment['pos_name'] ?? 'Tagihan',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Icon(
                  Icons.receipt_long,
                  color: Colors.teal,
                  size: 28,
                ),
              ],
            ),
            SizedBox(height: 15),
            Divider(color: Colors.grey[300], thickness: 1),
            SizedBox(height: 10),

            // Jumlah Tagihan (Untuk kedua jenis)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jumlah Tagihan:',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                Text(
                  'Rp ${numberFormat.format(int.tryParse(payment['bill'].toString()) ?? 0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            if (isMonthly) ...[
              // Untuk pembayaran bulanan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status:',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    payment['status'] == '1' ? 'Lunas' : 'Belum Lunas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color:
                          payment['status'] == '1' ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tanggal Bayar:',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    formatTanggal(payment['date_pay']),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Untuk pembayaran bebas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Terbayar:',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    'Rp ${numberFormat.format(int.tryParse(payment['total_pay'].toString()) ?? 0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sisa Pembayaran:',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    'Rp ${numberFormat.format((int.tryParse(payment['bill'].toString()) ?? 0) - (int.tryParse(payment['total_pay'].toString()) ?? 0))}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: ((int.tryParse(payment['bill'].toString()) ?? 0) -
                                  (int.tryParse(
                                          payment['total_pay'].toString()) ??
                                      0)) >
                              0
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Terakhir Diupdate:',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    formatTanggal(payment['last_update']),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMonthlyPayments =
        _filterDataByPeriod(_monthlyPayments, _selectedPeriod);
    final filteredFreePayments =
        _filterDataByPeriod(_freePayments, _selectedPeriod);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Data Pembayaran',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        elevation: 4,
        iconTheme: IconThemeData(
          color: Colors.white, // Set icon color to white
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: _showPeriodSelector,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(72, 75, 121, 119),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color.fromARGB(255, 255, 255, 255)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedPeriod != null
                          ? _periods.firstWhere((period) =>
                                  period['period_id'] ==
                                  _selectedPeriod)['period_start'] +
                              ' - ' +
                              _periods.firstWhere((period) =>
                                  period['period_id'] ==
                                  _selectedPeriod)['period_end']
                          : 'Periode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down,
                        color: const Color.fromARGB(255, 255, 255, 255)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: Colors.teal,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.teal,
                          tabs: [
                            Tab(text: 'Bulanan'),
                            Tab(text: 'Bebas'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildMonthlyPayments(filteredMonthlyPayments),
                              _buildFreePayments(filteredFreePayments),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMonthlyPayments(List<dynamic> payments) {
    final numberFormat = NumberFormat.decimalPattern('id');

    return payments.isEmpty
        ? Center(child: Text('Tidak ada data pembayaran bulanan.'))
        : ListView.separated(
            padding: EdgeInsets.all(16.0),
            itemCount: payments.length,
            separatorBuilder: (context, index) => Divider(),
            itemBuilder: (context, index) {
              final payment = payments[index];
              final isPaid = payment['status'] == '1';

              return ListTile(
                title: Text(
                  payment['pos_name'] ?? 'Pembayaran Bulanan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bulan: ${payment['month_name'] ?? '-'}'),
                    Text(
                        'Jumlah: Rp. ${numberFormat.format(int.tryParse(payment['bill'] ?? '0'))}'),
                  ],
                ),
                trailing: Icon(
                  isPaid ? Icons.check_circle : Icons.cancel,
                  color: isPaid ? Colors.green : Colors.red,
                ),
                onTap: () {
                  _showPaymentDetails(payment, true);
                },
              );
            },
          );
  }

  Widget _buildFreePayments(List<dynamic> payments) {
    final numberFormat = NumberFormat.decimalPattern('id');

    return payments.isEmpty
        ? Center(child: Text('Tidak ada data pembayaran bebas.'))
        : ListView.separated(
            padding: EdgeInsets.all(16.0),
            itemCount: payments.length,
            separatorBuilder: (context, index) => Divider(),
            itemBuilder: (context, index) {
              final payment = payments[index];
              final bill = payment['bill'] as int;
              final totalPay = payment['total_pay'] as int;
              final remaining = bill - totalPay;
              final isPaid = remaining <= 0;

              return ListTile(
                title: Text(
                  payment['pos_name'] ?? 'Pembayaran Bebas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.green.shade700 : Colors.black,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPaid)
                      Text('LUNAS',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ))
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terbayar: Rp${numberFormat.format(totalPay)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          Text(
                            'Sisa: Rp${numberFormat.format(remaining)}',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                trailing: Icon(
                  isPaid ? Icons.check_circle : Icons.payment,
                  color: isPaid ? Colors.green.shade700 : const Color.fromARGB(255, 210, 59, 25),
                ),
                onTap: () => _showPaymentDetails(payment, false),
              );
            },
          );
  }
}
