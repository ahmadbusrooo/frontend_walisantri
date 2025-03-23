import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class InformationDetailScreen extends StatelessWidget {
  final String title;
  final String description;
  final String? imageUrl;
  final String date;

  const InformationDetailScreen({
    super.key,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Informasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Html(
                    data: description,
                    style: {
                      "body": Style(
                        fontSize: FontSize(16.0),
                        lineHeight: const LineHeight(1.5),
                        color: Colors.black87,
                      ),
                      "p": Style(
                        margin: Margins.only(bottom: 12),
                      ),
                      "ul": Style(
                        margin: Margins.only(left: 20, bottom: 12),
                      ),
                      "ol": Style(
                        margin: Margins.only(left: 20, bottom: 12),
                      ),
                      "li": Style(
                        padding: HtmlPaddings.only(bottom: 4),
                      ),
                      "strong": Style(
                        fontWeight: FontWeight.bold,
                      ),
                      "em": Style(
                        fontStyle: FontStyle.italic,
                      ),
                    },
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