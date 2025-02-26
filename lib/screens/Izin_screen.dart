import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Izinscrenn extends StatefulWidget {
  @override
  _IzinscrennState createState() => _IzinscrennState();
}

class _IzinscrennState extends State<Izinscrenn> {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  violation['title'] ?? 'Unknown Title',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 10, 14, 14),
                  ),
                ),
              ),
              Icon(
                Icons.gavel,
                color: Colors.teal,
                size: 28,
              ),
            ],
          ),
          SizedBox(height: 15),
          Divider(color: Colors.grey[300], thickness: 1),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Deskripsi :',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              Text(
                violation['description'] ?? 'Tidak ada deskripsi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tanggal :',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              Text(
                violation['date'] ?? 'Tidak diketahui',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Point :',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              Text(
                violation['points'] ?? '0',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Catatan :',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              Expanded(
                child: Text(
                  violation['notes'] ?? 'Tidak ada catatan',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 110),
          
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
          'Data Perizinan',
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
  padding: const EdgeInsets.symmetric(horizontal: 16.0),
  child: Container(
    padding: EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.teal.shade700,
          Colors.teal.shade400,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 10,
          spreadRadius: 2,
          offset: Offset(4, 6), // Efek bayangan halus ke bawah dan ke kanan
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris pertama: Nama siswa, kelas, dan ikon di pojok kanan atas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _studentName,
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _className,
                  style: TextStyle(
                    fontSize: 16, 
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            Icon(Icons.gavel, color: Colors.white, size: 36), // Ikon di pojok kanan atas
          ],
        ),
        SizedBox(height: 12),

        // Total Hafalan
        Text(
          '$_totalViolations Hari Pulang',
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
            color: Colors.white,
          ),
        ),
        SizedBox(height: 6),

        // Kitab Hafalan
        
      ],
    ),
  ),
),
               SizedBox(height: 11),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _violations.length,
                    itemBuilder: (context, index) {
                      final violation = _violations[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                        child: ListTile(
                          title: Text(
                            violation['title'] ?? 'Unknown Title',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            violation['date'] ?? 'Tidak diketahui',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
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
