import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

String formatTanggal(String? tanggal) {
  if (tanggal == null || tanggal.isEmpty) return 'Tanggal tidak tersedia';

  try {
    DateTime parsedDate = DateTime.parse(tanggal.trim());
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(parsedDate);
  } catch (e) {
    return 'Format tidak valid';
  }
}

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  HealthScreenState createState() => HealthScreenState();
}

class HealthScreenState extends State<HealthScreen> {
  bool _isLoading = true;
  List<dynamic> _periods = [];
  List<dynamic> _healthData = [];
  String? _selectedPeriodId;
  String _studentName = "Tidak Diketahui";
  String _className = "Tidak Diketahui";
  Map<String, dynamic> _stats = {
    'total_sakit': 0,
    'masih_sakit': 0,
    'sudah_sembuh': 0,
    'rata_lama_sakit': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchPeriodsAndData();
  }

  Future<void> _fetchPeriodsAndData() async {
    try {
      final response = await ApiService.fetchHealthData();
      if (response['status']) {
        setState(() {
          _periods = response['data'];
          final activePeriod = _periods.firstWhere(
            (period) => period['period']['status'].toString() == '1',
            orElse: () => _periods.isNotEmpty ? _periods[0] : null,
          );
          _selectedPeriodId = activePeriod?['period']['period_id'];
          _updateSelectedPeriodData();
          _isLoading = false;
        });
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar(e.toString());
    }
  }

  void _updateSelectedPeriodData() {
    final selectedPeriod = _periods.firstWhere(
      (period) => period['period']['period_id'] == _selectedPeriodId,
      orElse: () => null,
    );

    if (selectedPeriod != null) {
      setState(() {
        _healthData = selectedPeriod['riwayat_kesehatan'];
        _stats = selectedPeriod['statistik'];
        _studentName = selectedPeriod['student']['full_name'];
        _className = selectedPeriod['student']['class_name'];
      });
    }
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
                    final period = _periods[index]['period'];
                    final isSelected = _selectedPeriodId == period['period_id'];
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
                        setState(() => _selectedPeriodId = period['period_id']);
                        _updateSelectedPeriodData();
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

  void _showHealthDetails(dynamic health) {
    final statusColor = _getStatusColor(health['status']);

    final tanggalSembuh =
        health['tanggal_sembuh']?.toString().trim().isNotEmpty == true
            ? formatTanggal(health['tanggal_sembuh'])
            : null;

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
                    Icon(Icons.local_hospital,
                        color: Colors.teal[600], size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        health['kondisi'] ?? 'Kondisi tidak diketahui',
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
                  icon: Icons.calendar_month_rounded,
                  children: [
                    _buildDetailItem(
                      'Tanggal Mulai',
                      formatTanggal(health['tanggal']),
                    ),
                    if (tanggalSembuh != null)
                      _buildDetailItem(
                        'Tanggal Sembuh',
                        tanggalSembuh,
                      ),
                  ],
                ),
                Divider(height: 32, color: Colors.grey[200]),
                _buildDetailSection(
                  icon: Icons.assignment_turned_in_rounded,
                  children: [
                    _buildDetailItem(
                      'Status',
                      health['status'],
                      valueColor: statusColor,
                    ),
                    _buildDetailItem(
                      'Tindakan',
                      health['tindakan'] ?? '-',
                    ),
                    _buildDetailItem(
                      'Catatan',
                      health['catatan'] ?? '-',
                    ),
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

  Color? _getStatusColor(String status) {
    switch (status) {
      case 'Masih Sakit':
        return Colors.orange[700];
      case 'Sudah Sembuh':
        return Colors.green[700];
      default:
        return Colors.teal[800];
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $message')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Data Kesehatan',
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
                      _selectedPeriodId != null
                          ? '${_periods.firstWhere((p) => p['period']['period_id'] == _selectedPeriodId)['period']['period_start']}/${_periods.firstWhere((p) => p['period']['period_id'] == _selectedPeriodId)['period']['period_end']}'
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
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _studentName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.teal[900],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _className,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.health_and_safety,
                                  color: Colors.teal[200], size: 32),
                            ],
                          ),
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey[200]!),
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                           child: GridView.count(
  shrinkWrap: true,
  crossAxisCount: 2,
  childAspectRatio: 2.5, // Diubah dari 3 ke 2.5 untuk mengurangi tinggi item
  physics: const NeverScrollableScrollPhysics(),
  crossAxisSpacing: 8, // Diubah dari 12 ke 8
  mainAxisSpacing: 8, // Diubah dari 12 ke 8
  padding: const EdgeInsets.all(4), // Tambahkan padding internal
  children: [
    _buildStatItem('Total Sakit', _stats['total_sakit']),
    _buildStatItem('Masih Sakit', _stats['masih_sakit']),
    _buildStatItem('Sudah Sembuh', _stats['sudah_sembuh']),
    _buildStatItem('Rata Lama Sakit', 
      '${_stats['rata_lama_sakit']} hari'),
  ],
),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _healthData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox,
                                  size: 48, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                "Belum ada riwayat kesehatan",
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _healthData.length,
                          separatorBuilder: (_, __) => SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final health = _healthData[index];
                            return Card(
  elevation: 0,
  color: health['status'] == 'Masih Sakit' 
      ? Colors.red[50] // Warna background lebih soft
      : Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: BorderSide(
      color: health['status'] == 'Masih Sakit' 
          ? Colors.red[100]! // Border merah muda
          : Colors.grey[200]!,
      width: 1,
    ),
  ),
  child: ListTile(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    leading: Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: health['status'] == 'Masih Sakit' 
            ? Colors.red[100] // Warna lingkaran lebih soft
            : Colors.teal.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.local_hospital,
        size: 20, 
        color: health['status'] == 'Masih Sakit' 
            ? Colors.red[600] // Tetap merah tapi hanya di icon
            : Colors.teal[600],
      ),
    ),
    title: Text(
      health['kondisi'] ?? 'Kondisi tidak diketahui',
      style: TextStyle(
        fontWeight: FontWeight.w500,
        color: health['status'] == 'Masih Sakit' 
            ? Colors.red[800] // Warna teks lebih gelap
            : Colors.teal[800],
      ),
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        formatTanggal(health['tanggal']),
        style: TextStyle(
          fontSize: 12, 
          color: health['status'] == 'Masih Sakit' 
              ? Colors.red[600]  // Warna subteks untuk status sakit
              : Colors.grey[600]),
        ),
    ),
    trailing: Icon(Icons.chevron_right_rounded,
        color: Colors.grey[400]),
    onTap: () => _showHealthDetails(health),
  ),
);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(String title, dynamic value) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 2),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
        ],
      ),
    );
  }
}