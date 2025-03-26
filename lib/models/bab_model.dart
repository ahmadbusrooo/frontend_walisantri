import 'package:intl/intl.dart';

class Bab {
  final String babId;
  final String amalanId;
  final String babTitle;
  final String babOrder;
  final DateTime createdAt;

  Bab({
    required this.babId,
    required this.amalanId,
    required this.babTitle,
    required this.babOrder,
    required this.createdAt,
  });

  String get formattedDate {
    return DateFormat('dd MMM yyyy HH:mm').format(createdAt);
  }

  factory Bab.fromJson(Map<String, dynamic> json) {
    return Bab(
      babId: json['bab_id'].toString(),
      amalanId: json['amalan_id'].toString(),
      babTitle: json['bab_title'],
      babOrder: json['bab_order'].toString(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class BabResponse {
  final bool status;
  final String message;
  final List<Bab> data;

  BabResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory BabResponse.fromJson(Map<String, dynamic> json) {
    return BabResponse(
      status: json['status'],
      message: json['message'] ?? '',
      data: (json['data'] as List)
          .map((e) => Bab.fromJson(e))
          .toList()
          ..sort((a, b) => a.babOrder.compareTo(b.babOrder)),
    );
  }
}