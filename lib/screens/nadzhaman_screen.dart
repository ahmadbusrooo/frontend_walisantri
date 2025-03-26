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

class NadzhamanScreen extends StatefulWidget {
  const NadzhamanScreen({super.key});
  @override
  _NadzhamanScreenState createState() => _NadzhamanScreenState();
}

class _NadzhamanScreenState extends State<NadzhamanScreen> {
  bool _isLoading = true;
  List<dynamic> _nadzhamanData = [];
  List<dynamic> _periods = [];
  String? _selectedPeriodId;
  int _totalHafalan = 0;
  String _studentName = "Tidak Diketahui";
  String _className = "Tidak Diketahui";
  List<dynamic> _kitabs = [];

  bool isNumeric(String? s) {
    if (s == null) return false;
    return double.tryParse(s) != null;
  }

  bool _showTotal = false;

  @override
  void initState() {
    super.initState();
    _fetchPeriodsAndData();
  }

  Future<void> _fetchPeriodsAndData() async {
    try {
      final response = await ApiService.fetchNadzhamanData();
      if (response['status']) {
        setState(() {
          _periods =
              response['data'].map((period) => period['period']).toList();
          final activePeriod = _periods.firstWhere(
            (period) => period['status'].toString() == '1', // Handle string/int
            orElse: () => _periods.isNotEmpty ? _periods[0] : null,
          );
          _selectedPeriodId =
              activePeriod != null ? activePeriod['period_id'] : null;
        });
        _fetchNadzhamanData(_selectedPeriodId);
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _fetchNadzhamanData(String? periodId) async {
    if (periodId == null) return;

    try {
      setState(() {
        _isLoading = true;
      });
      final response = await ApiService.fetchNadzhamanData();
      if (response['status']) {
        final selectedPeriodData = response['data'].firstWhere(
          (period) => period['period']['period_id'] == periodId,
          orElse: () => null,
        );

        setState(() {
          _nadzhamanData =
              selectedPeriodData != null ? selectedPeriodData['nadzhaman'] : [];
          _totalHafalan = selectedPeriodData != null
              ? selectedPeriodData['nadzhaman'].fold(0, (sum, item) {
                  final jml = item['jumlah_hafalan']?.toString() ?? '0';
                  return isNumeric(jml) ? sum + int.parse(jml) : sum;
                })
              : 0;

          // Cek apakah ada target atau jumlah hafalan numerik
          final hasNumericTarget = selectedPeriodData?['kitabs']?.any((kitab) =>
                  isNumeric(kitab['target_hafalan']?.toString() ?? '')) ??
              false;

          final hasNumericJumlah = selectedPeriodData?['nadzhaman']?.any(
                  (item) =>
                      isNumeric(item['jumlah_hafalan']?.toString() ?? '')) ??
              false;

          _showTotal = hasNumericTarget || hasNumericJumlah;

          _studentName =
              selectedPeriodData?['student']?['full_name'] ?? "Tidak Diketahui";
          _className = selectedPeriodData?['student']?['class_name'] ??
              "Tidak Diketahui";
          _kitabs = selectedPeriodData?['kitabs'] ?? [];

          _isLoading = false;
        });
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
                    final period = _periods[index];
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
                        setState(() {
                          _selectedPeriodId = period['period_id'];
                        });
                        _fetchNadzhamanData(period['period_id']);
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

  void _showNadzhamanDetails(dynamic nadzhaman) {
    final statusColor = nadzhaman['status'] == 'Khatam'
        ? Colors.green[700]
        : Colors.orange[700];

    final tanggalAkhir =
        nadzhaman['tanggal_akhir']?.toString().trim().isNotEmpty == true
            ? formatTanggal(nadzhaman['tanggal_akhir'])
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
                    Icon(Icons.auto_stories_rounded,
                        color: Colors.teal[600], size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        nadzhaman['nama_kitab'] ?? 'Kitab Tanpa Judul',
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
                      formatTanggal(nadzhaman['tanggal']),
                    ),
                    if (tanggalAkhir != null)
                      _buildDetailItem(
                        'Tanggal Selesai',
                        tanggalAkhir,
                      ),
                  ],
                ),
                Divider(height: 32, color: Colors.grey[200]),
                _buildDetailSection(
                  icon: Icons.assignment_turned_in_rounded,
                  children: [
                    _buildDetailItem(
                      'Jumlah Hafalan',
                      isNumeric(nadzhaman['jumlah_hafalan']?.toString())
                          ? '${nadzhaman['jumlah_hafalan']} Nadzham'
                          : nadzhaman['jumlah_hafalan']?.toString() ?? '-',
                    ),
                    _buildDetailItem(
                      'Status',
                      nadzhaman['status'] ?? '-',
                      valueColor: statusColor,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Data Hafalan',
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
                          ? '${_periods.firstWhere((p) => p['period_id'] == _selectedPeriodId)['period_start']}/${_periods.firstWhere((p) => p['period_id'] == _selectedPeriodId)['period_end']}'
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
                              Icon(Icons.school_rounded,
                                  color: Colors.teal[200], size: 32),
                            ],
                          ),
                          SizedBox(height: 16),
                          if (_showTotal)
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.grey[200]!),
                                  bottom: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Nadzham',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '$_totalHafalan',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_kitabs.isNotEmpty) ...[
                            SizedBox(height: 12),
                            Text(
                              'Kitab yang Dipelajari:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            ..._kitabs.map((kitab) {
                              final target =
                                  kitab['target_hafalan']?.toString() ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Icon(Icons.bookmark,
                                        size: 14, color: Colors.teal[300]),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            kitab['nama_kitab'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.teal[800],
                                            ),
                                          ),
                                          Text(
                                            isNumeric(target)
                                                ? 'Target: $target Nadzham'
                                                : 'Target: $target',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _nadzhamanData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox,
                                  size: 48, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                "Belum ada catatan hafalan",
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _nadzhamanData.length,
                          separatorBuilder: (_, __) => SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final nadzhaman = _nadzhamanData[index];
                            final jmlHafalan =
                                nadzhaman['jumlah_hafalan']?.toString() ?? '';

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                leading: Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.library_books_rounded,
                                      size: 20, color: Colors.teal[600]),
                                ),
                                title: Text(
                                  isNumeric(jmlHafalan)
                                      ? '$jmlHafalan Nadzham'
                                      : jmlHafalan,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: isNumeric(jmlHafalan)
                                        ? Colors.teal[800]
                                        : Colors.orange[700],
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    formatTanggal(nadzhaman['tanggal']),
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ),
                                trailing: Icon(Icons.chevron_right_rounded,
                                    color: Colors.grey[400]),
                                onTap: () => _showNadzhamanDetails(nadzhaman),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
