import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'custom_bottom_navigation_bar.dart';
import 'information_detail_screen.dart';

class InformationScreen extends StatefulWidget {
  @override
  _InformationScreenState createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  List<dynamic> informations = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool isLoading = true;
  bool hasError = false;
  bool isLoadingMore = false;
  
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchInformations();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      if (!isLoadingMore && _currentPage < _totalPages) {
        _loadMoreData();
      }
    }
  }

  Future<void> _fetchInformations({bool refresh = false}) async {
    try {
      if (refresh) {
        _currentPage = 1;
        informations.clear();
      }

      final response = await ApiService.fetchInformationData(
        page: _currentPage,
        limit: 10,
      );

      setState(() {
        _totalPages = response['data']['total_pages'];
        informations.addAll(response['data']['informations']);
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (isLoadingMore || _currentPage >= _totalPages) return;

    setState(() => isLoadingMore = true);
    
    try {
      _currentPage++;
      final response = await ApiService.fetchInformationData(
        page: _currentPage,
        limit: 10,
      );

      setState(() {
        informations.addAll(response['data']['informations']);
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() => isLoadingMore = false);
      _currentPage--; // Rollback page if error
    }
    
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Informasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(

          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchInformations(refresh: true),
        child: _buildBody(),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 2),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Gagal memuat informasi',
              style: TextStyle(fontSize: 18),
            ),
            TextButton(
              onPressed: () => _fetchInformations(refresh: true),
              child: Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (informations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.teal),
            SizedBox(height: 16),
            Text(
              'Tidak ada informasi tersedia',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: informations.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index >= informations.length) {
          return _buildLoadingIndicator();
        }
        return _buildInformationCard(informations[index]);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildInformationCard(Map<String, dynamic> info) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InformationDetailScreen(
                title: info['information_title'] ?? 'Judul Tidak Tersedia',
                description: info['information_desc'] ?? '',
                imageUrl: info['image_url'],
                date: info['formatted_date'] ?? '',
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (info['image_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  info['image_url'],
                  height: 180,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, size: 60),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info['information_title'] ?? 'Judul Tidak Tersedia',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        info['formatted_date'] ?? 'Tanggal tidak tersedia',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    (info['information_desc']?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '')
                        .replaceAll('\n', ' '),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}