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

class ViolationScreen extends StatefulWidget {
  const ViolationScreen({super.key});
  @override
  _ViolationScreenState createState() => _ViolationScreenState();
}

class _ViolationScreenState extends State<ViolationScreen> {
  bool _isLoading = true;
  List<dynamic> _periods = [];
  String? _selectedPeriodId;
  List<dynamic> _allViolations = [];
  List<dynamic> _filteredViolations = [];
  String _selectedViolationType = 'all'; // 'all', 'umum', 'jamaah', 'mengaji'
  Map<String, dynamic> _stats = {};
  String _studentName = "Tidak Diketahui";
  String _className = "Tidak Diketahui";

  @override
  void initState() {
    super.initState();
    _fetchPeriodsAndData();
  }

  Future<void> _fetchPeriodsAndData() async {
    try {
      final response = await ApiService.fetchViolationData();
      if (response['status']) {
        setState(() {
          _periods = response['data'].map((period) => period['period']).toList();
          final activePeriod = _periods.firstWhere(
            (period) => period['status'] == 'Aktif',
            orElse: () => _periods.isNotEmpty ? _periods[0] : null,
          );
          _selectedPeriodId = activePeriod != null ? activePeriod['id'] : null;
        });
        _fetchViolationData(_selectedPeriodId);
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

  Future<void> _fetchViolationData(String? periodId) async {
    if (periodId == null) return;

    try {
      setState(() {
        _isLoading = true;
      });
      final response = await ApiService.fetchViolationData();
      if (response['status']) {
        final selectedPeriodData = response['data'].firstWhere(
          (period) => period['period']['id'] == periodId,
          orElse: () => null,
        );

        if (selectedPeriodData != null) {
          setState(() {
            _allViolations = selectedPeriodData['detail_pelanggaran'];
            _stats = selectedPeriodData['statistik'];
            _studentName = selectedPeriodData['siswa']['nama_lengkap'];
            _className = selectedPeriodData['siswa']['kelas'];
            _applyFilters();
            _isLoading = false;
          });
        } else {
          throw Exception("Data tidak ditemukan");
        }
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

  void _applyFilters() {
    setState(() {
      _filteredViolations = _allViolations.where((violation) {
        if (_selectedViolationType == 'all') return true;
        return violation['jenis'] == _selectedViolationType;
      }).toList();
    });
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
                    final isSelected = _selectedPeriodId == period['id'];
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      tileColor: isSelected ? Colors.teal.shade100 : null,
                      leading: CircleAvatar(
                        backgroundColor:
                            isSelected ? Colors.teal : Colors.teal.shade100,
                        child: Icon(Icons.calendar_today, color: Colors.white),
                      ),
                      title: Text(
                        '${period['tahun_ajaran']}',
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
                          _selectedPeriodId = period['id'];
                        });
                        _fetchViolationData(period['id']);
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

  Widget _buildTypeFilter() {
    const types = {
      'all': 'Semua',
      'umum': 'Umum',
      'jamaah': 'Jamaah',
      'mengaji': 'Mengaji'
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: types.entries.map((entry) {
          final isSelected = _selectedViolationType == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedViolationType = entry.key;
                  _applyFilters();
                });
              },
              selectedColor: Colors.teal.shade100,
              checkmarkColor: Colors.teal.shade700,
              labelStyle: TextStyle(
                color: isSelected ? Colors.teal.shade800 : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? Colors.teal.shade300 : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsCard() {
     List<Widget> statsWidgets = [];

  // Fungsi untuk membangun item statistik
  Widget buildStatItem(String jenis, IconData icon, Color color) {
    String title = '';
    String value = '0';
    
    switch(jenis) {
      case 'umum':
        title = 'Total Pelanggaran Umum';
        value = _stats.containsKey('umum') ? _stats['umum']['total_poin'].toString() : '0';
        break;
      case 'jamaah':
        title = 'Total Absen Jamaah';
        value = _stats.containsKey('jamaah') ? _stats['jamaah']['total_absen'].toString() : '0';
        break;
      case 'mengaji':
        title = 'Total Absen Mengaji';
        value = _stats.containsKey('mengaji') ? _stats['mengaji']['total_absen'].toString() : '0';
        break;
    }

    return _buildStatItem(
      icon: icon,
      title: title,
      value: value,
      color: color,
    );
  }

  // Logika pemilihan statistik berdasarkan filter
  if (_selectedViolationType == 'all') {
    // Tampilkan semua statistik
    statsWidgets.addAll([
      buildStatItem('umum', Icons.warning_amber_rounded, Colors.orange[700]!),
      Divider(height: 16, color: Colors.grey[200]),
      buildStatItem('jamaah', Icons.mosque_rounded, Colors.red[700]!),
      Divider(height: 16, color: Colors.grey[200]),
      buildStatItem('mengaji', Icons.menu_book_rounded, Colors.blue[700]!),
    ]);
  } else {
    // Tampilkan statistik sesuai jenis yang dipilih
    switch(_selectedViolationType) {
      case 'umum':
        statsWidgets.add(
          buildStatItem('umum', Icons.warning_amber_rounded, Colors.orange[700]!)
        );
        break;
      case 'jamaah':
        statsWidgets.add(
          buildStatItem('jamaah', Icons.mosque_rounded, Colors.red[700]!)
        );
        break;
      case 'mengaji':
        statsWidgets.add(
          buildStatItem('mengaji', Icons.menu_book_rounded, Colors.blue[700]!)
        );
        break;
    }
  }

  return Container(
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
    padding: EdgeInsets.all(16),
    child: Column(
      children: statsWidgets,
    ),
  );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (color ?? Colors.teal[700])!.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color ?? Colors.teal[700]),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.teal[800],
            ),
          ),
        ],
      ),
    );
  }

  void _showViolationDetails(dynamic violation) {
    final jenis = violation['jenis'];
    final violationColor = _getViolationColor(jenis);
    final IconData violationIcon = _getViolationIcon(jenis);
    
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
                    Icon(violationIcon, color: violationColor, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        violation['judul'] ?? 'Pelanggaran Tanpa Judul',
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
                
                if (jenis == 'umum') ...[
                  _buildDetailSection(
                    icon: Icons.calendar_month_rounded,
                    children: [
                      _buildDetailItem(
                        'Tanggal',
                        formatTanggal(violation['tanggal']),
                      ),
                    ],
                  ),
                  Divider(height: 32, color: Colors.grey[200]),
                  _buildDetailSection(
                    icon: Icons.warning_amber_rounded,
                    children: [
                      _buildDetailItem(
                        'Deskripsi',
                        violation['deskripsi'] ?? '-',
                      ),
                      _buildDetailItem(
                        'Pelanggaran',
                        '${violation['poin']} Pelanggaran',
                        valueColor: Colors.orange[700],
                      ),
                    ],
                  ),
                ],
                
                if (jenis == 'jamaah' || jenis == 'mengaji') ...[
                  _buildDetailSection(
                    icon: Icons.calendar_month_rounded,
                    children: [
                      _buildDetailItem(
                        'Periode',
                        '${formatTanggal(violation['periode_absen']['mulai'])} - '
                        '${formatTanggal(violation['periode_absen']['selesai'])}',
                      ),
                    ],
                  ),
                  Divider(height: 32, color: Colors.grey[200]),
                  _buildDetailSection(
                    icon: jenis == 'jamaah' ? Icons.mosque_rounded : Icons.menu_book_rounded,
                    children: [
                      _buildDetailItem(
                        'Jumlah Absen',
                        '${violation['jumlah_absen']}x',
                        valueColor: jenis == 'jamaah' ? Colors.red[700] : Colors.blue[700],
                      ),
                    ],
                  ),
                ],
                
                if (violation['catatan'] != null && violation['catatan'].toString().isNotEmpty) ...[
                  Divider(height: 32, color: Colors.grey[200]),
                  _buildDetailSection(
                    icon: Icons.note_alt_outlined,
                    children: [
                      _buildDetailItem(
                        'Catatan',
                        violation['catatan'],
                      ),
                    ],
                  ),
                ],
                
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

  Widget _buildDetailSection({
    required IconData icon,
    required List<Widget> children,
  }) {
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

  IconData _getViolationIcon(String jenis) {
    switch (jenis) {
      case 'umum': return Icons.warning_amber_rounded;
      case 'jamaah': return Icons.mosque_rounded;
      case 'mengaji': return Icons.menu_book_rounded;
      default: return Icons.error_outline;
    }
  }

  Color _getViolationColor(String jenis) {
    switch (jenis) {
      case 'umum': return Colors.orange[700]!;
      case 'jamaah': return Colors.red[700]!;
      case 'mengaji': return Colors.blue[700]!;
      default: return Colors.grey[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Data Pelanggaran',
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
                          ? '${_periods.firstWhere((p) => p['id'] == _selectedPeriodId)['tahun_ajaran']}'
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
                              Icon(Icons.account_circle,
                                  color: Colors.teal[200], size: 32),
                            ],
                          ),
                          SizedBox(height: 16),
                          Divider(height: 16, color: Colors.grey[200]),
                          _buildTypeFilter(),
                          SizedBox(height: 16),
                          _buildStatsCard(),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredViolations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 48, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                "Tidak ada data pelanggaran",
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredViolations.length,
                          separatorBuilder: (_, __) => SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final violation = _filteredViolations[index];
                            final jenis = violation['jenis'];
                            
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
                                    color: _getViolationColor(jenis).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_getViolationIcon(jenis),
                                      size: 20, color: _getViolationColor(jenis)),
                                ),
                                title: Text(
                                  violation['judul'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.teal[800],
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    jenis == 'umum'
                                        ? formatTanggal(violation['tanggal'])
                                        : 'Periode: ${formatTanggal(violation['periode_absen']['mulai'])}',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getViolationColor(jenis).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        jenis == 'umum'
                                            ? '${violation['poin']} '
                                            : '${violation['jumlah_absen']}x',
                                        style: TextStyle(
                                          color: _getViolationColor(jenis),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: Colors.grey[400]),
                                  ],
                                ),
                                onTap: () => _showViolationDetails(violation),
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