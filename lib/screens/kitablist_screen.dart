import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; 
import '../services/api_service.dart';
import 'bab_screen.dart'; 
// Model classes
class AmalanResponse {
  final bool status;
  final String message;
  final List<Amalan> data;

  AmalanResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory AmalanResponse.fromJson(Map<String, dynamic> json) {
    return AmalanResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => Amalan.fromJson(e))
              .toList() ??
          [],
    );
  }

  static AmalanResponse parse(String response) {
    return AmalanResponse.fromJson(json.decode(response));
  }
}

class Amalan {
  final String id;
  final String title;
  final String slug;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  Amalan({
    required this.id,
    required this.title,
    required this.slug,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Amalan.fromJson(Map<String, dynamic> json) {
    return Amalan(
      id: json['amalan_id']?.toString() ?? '',
      title: json['amalan_title']?.toString() ?? '',
      slug: json['amalan_slug']?.toString() ?? '',
      isPublished: (json['amalan_publish']?.toString() ?? '0') == '1',
      createdAt: _parseDateTime(json['created_at']?.toString()),
      updatedAt: _parseDateTime(json['updated_at']?.toString()),
    );
  }

  static DateTime _parseDateTime(String? dateString) {
    try {
      return dateString != null ? DateTime.parse(dateString) : DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'amalan_id': id,
      'amalan_title': title,
      'amalan_slug': slug,
      'amalan_publish': isPublished ? '1' : '0',
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Model classes remain the same as in the original code
// (AmalanResponse and Amalan classes)
class KitablistScreen extends StatefulWidget {
  const KitablistScreen({super.key});
  @override
  _KitablistScreenState createState() => _KitablistScreenState();
}

class _KitablistScreenState extends State<KitablistScreen> {
  bool _isLoading = true;
  List<Amalan> _amalanList = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAmalanData();
  }

  Future<void> _fetchAmalanData() async {
    try {
      final Map<String, dynamic> responseData = await ApiService.fetchAmalanData();
      final AmalanResponse response = AmalanResponse.fromJson(responseData);
      if (response.status) {
        setState(() {
          _amalanList = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data amalan: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToBabScreen(String amalanId, String amalanTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BabScreen(
          amalanId: amalanId,
          amalanTitle: amalanTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Koleksi Kitab',
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

    if (_amalanList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_books, 
                size: 48, 
                color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              "Tidak ada data kitab tersedia",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _amalanList.length,
      separatorBuilder: (_, __) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final amalan = _amalanList[index];
        return _buildAmalanCard(amalan);
      },
    );
  }

  Widget _buildAmalanCard(Amalan amalan) {
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
            Icons.menu_book_rounded, 
            size: 20, 
            color: Colors.teal[600]
          ),
        ),
        title: Text(
          amalan.title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.teal[800],
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              if (amalan.isPublished)
                Row(
                  children: [
                    Icon(
                      Icons.check_circle, 
                      color: Colors.green[700], 
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Tersedia',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey[400]
        ),
        onTap: () => _navigateToBabScreen(amalan.id, amalan.title),
      ),
    );
  }
}