import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ViolationScreen extends StatefulWidget {
  @override
  _ViolationScreenState createState() => _ViolationScreenState();
}

class _ViolationScreenState extends State<ViolationScreen> {
  bool _isLoading = true;
  List<dynamic> _periods = [];
  String? _selectedPeriodId;
  List<dynamic> _violations = [];
  int _totalViolations = 0;
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
            (period) => period['status'] == '1',
            orElse: () => _periods.isNotEmpty ? _periods[0] : null,
          );
          _selectedPeriodId = activePeriod != null ? activePeriod['period_id'] : null;
        });
        _fetchViolationData(_selectedPeriodId);
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

  Future<void> _fetchViolationData(String? periodId) async {
    if (periodId == null) return;

    try {
      setState(() {
        _isLoading = true;
      });
      final response = await ApiService.fetchViolationData();
      if (response['status']) {
        final selectedPeriodData = response['data'].firstWhere(
          (period) => period['period']['period_id'] == periodId,
          orElse: () => null,
        );

        setState(() {
          _violations = selectedPeriodData != null ? selectedPeriodData['pelanggaran'] : [];
 _totalViolations = selectedPeriodData['total_pelanggaran'] is int
    ? selectedPeriodData['total_pelanggaran']
    : int.tryParse(selectedPeriodData['total_pelanggaran'] ?? '0') ?? 0;
          _studentName = selectedPeriodData?['student']?['full_name'] ?? "Tidak Diketahui";
          _className = selectedPeriodData?['student']?['class_name'] ?? "Tidak Diketahui";
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
              colors: [const Color.fromARGB(255, 255, 255, 255), const Color.fromARGB(255, 255, 255, 255)],
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
                        backgroundColor: isSelected ? Colors.teal : Colors.teal.shade100,
                        child: Icon(Icons.calendar_today, color: Colors.white),
                      ),
                      title: Text(
                        '${period['period_start']} - ${period['period_end']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.teal.shade900 : Colors.black87,
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
                        _fetchViolationData(period['period_id']);
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

  void _showViolationDetails(dynamic violation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(violation['title'] ?? 'Unknown Title', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Deskripsi: ${violation['description'] ?? 'Tidak ada deskripsi'}'),
            Text('Tanggal: ${violation['date'] ?? 'Tidak diketahui'}'),
            Text('Catatan: ${violation['notes'] ?? 'Tidak ada catatan'}'),
            Text('Poin: ${violation['points'] ?? '0'}'),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Data Pelanggaran',
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
                  border: Border.all(color: const Color.fromARGB(255, 255, 255, 255)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedPeriodId != null
                          ? _periods.firstWhere((period) => period['period_id'] == _selectedPeriodId)['period_start'] +
                              ' - ' +
                              _periods.firstWhere((period) => period['period_id'] == _selectedPeriodId)['period_end']
                          : 'Periode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: const Color.fromARGB(255, 255, 255, 255)),
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
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade700,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_studentName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 4),
                        Text(_className, style: TextStyle(fontSize: 16, color: Colors.white70)),
                        SizedBox(height: 12),
                        Text('$_totalViolations Pelanggaran', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _violations.length,
                    itemBuilder: (context, index) {
                      final violation = _violations[index];
                      return Card(
                        child: ListTile(
                          title: Text(violation['title'] ?? 'Unknown Title'),
                          subtitle: Text(violation['date'] ?? 'Tidak diketahui'),
                          trailing: Icon(Icons.info_outline, color: Colors.teal),
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
