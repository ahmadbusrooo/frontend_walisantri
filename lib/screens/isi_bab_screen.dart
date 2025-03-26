import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/isi_bab_model.dart';

class IsiBabScreen extends StatefulWidget {
  final String babId;
  final String babTitle;
  final String languageCode;

  const IsiBabScreen({
    Key? key,
    required this.babId,
    required this.babTitle,
    this.languageCode = 'ar',
  }) : super(key: key);

  @override
  State<IsiBabScreen> createState() => _IsiBabScreenState();
}

class _IsiBabScreenState extends State<IsiBabScreen> {
  bool _isLoading = true;
  IsiBabResponse? _isiBab;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchIsiBabData();
  }

  Future<void> _fetchIsiBabData() async {
    try {
      final response = await ApiService.fetchIsiData(
        int.parse(widget.babId), 
        languageCode: widget.languageCode
      );
      final IsiBabResponse isiResponse = IsiBabResponse.fromJson(response);
      
      if (isiResponse.status) {
        setState(() {
          _isiBab = isiResponse;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = isiResponse.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat konten bab';
        _isLoading = false;
      });
    }
  }

  TextDirection _getTextDirection() {
    switch (widget.languageCode) {
      case 'ar': // Arabic
      case 'fa': // Persian
      case 'ur': // Urdu
        return TextDirection.rtl;
      default:
        return TextDirection.ltr;
    }
  }

  TextStyle _getLanguageFont(double fontSize) {
    switch (widget.languageCode) {
      case 'ar': // Arabic
        return TextStyle(
          fontFamily: 'LPMQ IsepMisbah',
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        );
      case 'fa': // Persian
        return GoogleFonts.vazirmatn(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        );
      case 'ur': // Urdu
        return GoogleFonts.notoNastaliqUrdu(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        );
      default:
        return GoogleFonts.roboto(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5), 
      appBar: AppBar(
        title: Text(
          widget.babTitle,
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
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.teal[900]),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_outlined, size: 64, color: Colors.teal[200]),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.teal[900],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isiBab == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, size: 64, color: Colors.teal[200]),
            SizedBox(height: 16),
            Text(
              "Tidak ada konten tersedia",
              style: TextStyle(
                color: Colors.teal[900],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.teal.shade100,
                  width: 1.5,
                ),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _isiBab!.babDetail.babTitle,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.teal[900],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.format_list_numbered, 
                        color: Colors.teal[300], size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Bab ${_isiBab!.babDetail.babOrder}',
                      style: TextStyle(
                        color: Colors.teal[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Html(
              data: _isiBab!.isiContent.content,
              style: {
                "html": Style(
                  fontSize: FontSize(20),
                  textAlign: TextAlign.start,
                  fontFamily: _getLanguageFont(18).fontFamily,
                  lineHeight: LineHeight(1.8),
                ),
                "p": Style(
              padding: HtmlPaddings(bottom: HtmlPadding(12)),
            ),
            "strong": Style(
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
                "table": Style(
                  border: Border.all(color: Colors.teal.shade200, width: 1),
                ),
                "th": Style(
                  backgroundColor: Colors.teal.shade100,
                  padding: HtmlPaddings.all(8),
                  border: Border.all(color: Colors.teal.shade200, width: 1),
                ),
                "td": Style(
                  padding: HtmlPaddings.all(8),
                  border: Border.all(color: Colors.teal.shade100, width: 1),
                ),
              },
            ),
          ),
        ),
      ],
    );
  }
}