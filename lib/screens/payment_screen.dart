import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../utils/shared_preferences_helper.dart';
import '../services/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
  bool _isOffline = false; // Tambahkan ini
  Map<String, dynamic>? _cachedData; // Tambahkan untuk cache data

  @override
  void initState() {
    super.initState();
    _fetchPaymentData();
  }

  Future<void> _fetchPaymentData() async {
    setState(() {
      _isLoading = true;
      _isOffline = false;
    });

    try {
      // Cek koneksi internet
      final isConnected = await ConnectivityService.isConnected();
      if (!isConnected) {
        setState(() => _isOffline = true);
        throw Exception('Tidak ada koneksi internet');
      }

      final response = await ApiService.fetchPaymentData();

      if (response['status']) {
        // Simpan data ke cache
        await SharedPreferencesHelper.savePaymentData(
            jsonEncode(response['data']));
        _processData(response['data']);
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      // Coba load data dari cache jika ada
      final cachedData = await SharedPreferencesHelper.getPaymentData();
      if (cachedData != null) {
        _processData(jsonDecode(cachedData));
      }

      setState(() => _isOffline = true);
      _showErrorSnackbar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _processData(dynamic data) {
    setState(() {
      // Menyiapkan data periode
      _periods = data.map((period) {
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
      data.forEach((period) {
        final bulanDetails = period['payments']['bulan']['details'] ?? [];
        bulanDetails.forEach((detail) {
          detail['period_id'] = period['period']['period_id'];
          _monthlyPayments.add(detail);
        });
      });

      // Menyiapkan pembayaran bebas secara manual
      _freePayments = [];
      data.forEach((period) {
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

      _isOffline = false;
    });
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $message')),
    );
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
                  color: const Color.fromARGB(255, 130, 155, 153),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Pilih Tahun Ajaran',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 0, 0, 0),
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
    final statusColor = isMonthly
        ? (payment['status'] == '1' ? Colors.green[700] : Colors.orange[700])
        : ((int.tryParse(payment['bill'].toString()) ?? 0) -
                    (int.tryParse(payment['total_pay'].toString()) ?? 0) <=
                0
            ? Colors.green[700]
            : Colors.orange[700]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.teal[600], size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        payment['pos_name'] ?? 'Tagihan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal[900],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                _buildDetailSection(
                  icon: Icons.payment,
                  children: [
                    _buildDetailItem(
                      'Jumlah Tagihan',
                      'Rp ${numberFormat.format(int.tryParse(payment['bill'].toString()) ?? 0)}',
                    ),
                    if (isMonthly) ...[
                      _buildDetailItem(
                        'Status',
                        payment['status'] == '1' ? 'Lunas' : 'Belum Lunas',
                        valueColor: statusColor,
                      ),
                      _buildDetailItem(
                        'Tanggal Bayar',
                        formatTanggal(payment['date_pay']),
                      ),
                      if (!isMonthly && payment['month_name'] != null)
                        _buildDetailItem(
                          'Bulan',
                          payment['month_name'],
                        ),
                    ] else ...[
                      _buildDetailItem(
                        'Terbayar',
                        'Rp ${numberFormat.format(int.tryParse(payment['total_pay'].toString()) ?? 0)}',
                      ),
                      _buildDetailItem(
                        'Sisa Pembayaran',
                        'Rp ${numberFormat.format((int.tryParse(payment['bill'].toString()) ?? 0) - (int.tryParse(payment['total_pay'].toString()) ?? 0))}',
                        valueColor:
                            ((int.tryParse(payment['bill'].toString()) ?? 0) -
                                        (int.tryParse(payment['total_pay']
                                                .toString()) ??
                                            0)) >
                                    0
                                ? Colors.red[600]
                                : Colors.green[600],
                      ),
                      _buildDetailItem(
                        'Terakhir Diupdate',
                        formatTanggal(payment['last_update']),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Tutup', style: TextStyle(fontSize: 16)),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
      {required IconData icon, required List<Widget> children}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.teal[300]),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: valueColor ?? Colors.teal[900],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal[700],
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: _showPeriodSelector,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.teal[600],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white54, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      _selectedPeriod != null
                          ? '${_periods.firstWhere((period) => period['period_id'] == _selectedPeriod)['period_start']}/${_periods.firstWhere((period) => period['period_id'] == _selectedPeriod)['period_end']}'
                          : 'Pilih Periode',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : Column(
              children: [
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Container(
                          color: Colors.white,
                          child: TabBar(
                            labelColor: Colors.teal[700],
                            unselectedLabelColor: Colors.grey[600],
                            indicatorColor: Colors.teal[700],
                            indicatorWeight: 3,
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            tabs: [
                              Tab(text: 'Bulanan'),
                              Tab(text: 'Bebas'),
                            ],
                          ),
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
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  "Belum ada data pembayaran bulanan",
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          )
        : ListView.separated(
            padding: EdgeInsets.all(16.0),
            itemCount: payments.length,
            separatorBuilder: (context, index) => SizedBox(height: 8),
            itemBuilder: (context, index) {
              final payment = payments[index];
              final isPaid = payment['status'] == '1';

              return Card(
                elevation: 0,
                color: isPaid ? Colors.green[50] : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isPaid ? Colors.green[100]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? Colors.green[100]
                          : Colors.teal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPaid ? Icons.check_circle : Icons.payment,
                      size: 20,
                      color: isPaid ? Colors.green[600] : Colors.teal[600],
                    ),
                  ),
                  title: Text(
                    payment['pos_name'] ?? 'Pembayaran Bulanan',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isPaid ? Colors.green[800] : Colors.teal[800],
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bulan: ${payment['month_name'] ?? '-'}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isPaid ? Colors.green[600] : Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Rp. ${numberFormat.format(int.tryParse(payment['bill'] ?? '0'))}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                isPaid ? Colors.green[600] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: Colors.grey[400]),
                  onTap: () => _showPaymentDetails(payment, true),
                ),
              );
            },
          );
  }

  Widget _buildFreePayments(List<dynamic> payments) {
    final numberFormat = NumberFormat.decimalPattern('id');

    return payments.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  "Belum ada data pembayaran bebas",
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          )
        : ListView.separated(
            padding: EdgeInsets.all(16.0),
            itemCount: payments.length,
            separatorBuilder: (context, index) => SizedBox(height: 8),
            itemBuilder: (context, index) {
              final payment = payments[index];
              final bill = payment['bill'] as int;
              final totalPay = payment['total_pay'] as int;
              final remaining = bill - totalPay;
              final isPaid = remaining <= 0;

              return Card(
                elevation: 0,
                color: isPaid
                    ? Colors.green[50]
                    : (remaining > 0 ? Colors.orange[50] : Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isPaid
                        ? Colors.green[100]!
                        : (remaining > 0
                            ? Colors.orange[100]!
                            : Colors.grey[200]!),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? Colors.green[100]
                          : (remaining > 0
                              ? Colors.orange[100]
                              : Colors.teal.withOpacity(0.1)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPaid ? Icons.check_circle : Icons.payment,
                      size: 20,
                      color: isPaid
                          ? Colors.green[600]
                          : (remaining > 0
                              ? Colors.orange[600]
                              : Colors.teal[600]),
                    ),
                  ),
                  title: Text(
                    payment['pos_name'] ?? 'Pembayaran Bebas',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isPaid
                          ? Colors.green[800]
                          : (remaining > 0
                              ? Colors.orange[800]
                              : Colors.teal[800]),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isPaid)
                          Text(
                            'LUNAS',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[600]),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Terbayar: Rp${numberFormat.format(totalPay)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Sisa: Rp${numberFormat.format(remaining)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red[600],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: Colors.grey[400]),
                  onTap: () => _showPaymentDetails(payment, false),
                ),
              );
            },
          );
  }
}
