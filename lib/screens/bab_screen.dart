import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/bab_model.dart';
import 'isi_bab_screen.dart';

class BabScreen extends StatefulWidget {
  final String amalanId;
  final String amalanTitle;

  const BabScreen({
    super.key,
    required this.amalanId,
    required this.amalanTitle,
  });

  @override
  _BabScreenState createState() => _BabScreenState();
}

class _BabScreenState extends State<BabScreen> {
  bool _isLoading = true;
  List<Bab> _babList = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchBabData();
  }

  Future<void> _fetchBabData() async {
    try {
      final response = await ApiService.fetchBabData(widget.amalanId);
      final BabResponse babResponse = BabResponse.fromJson(response);
      
      if (babResponse.status) {
        setState(() {
          _babList = babResponse.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = babResponse.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data bab: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToIsiBabScreen(Bab bab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IsiBabScreen(
          babId: bab.babId,
          babTitle: bab.babTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.amalanTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal[700],
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, 
                size: 48, 
                color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_babList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt_rounded, 
                size: 48, 
                color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              "Belum ada bab tersedia untuk kitab ini",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _babList.length,
      separatorBuilder: (_, __) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final bab = _babList[index];
        return _buildBabCard(bab);
      },
    );
  }

  Widget _buildBabCard(Bab bab) {
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
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.article_rounded, 
            size: 20, 
            color: Colors.teal[600]
          ),
        ),
        title: Text(
          bab.babTitle,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.teal[800],
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Urutan Bab: ${bab.babOrder}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey[400]
        ),
        onTap: () => _navigateToIsiBabScreen(bab),
      ),
    );
  }
}