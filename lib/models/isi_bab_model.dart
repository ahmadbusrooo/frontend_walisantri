class BabDetail {
  final String babId;
  final String amalanId;
  final String babTitle;
  final String babOrder;
  final DateTime createdAt;

  BabDetail({
    required this.babId,
    required this.amalanId,
    required this.babTitle,
    required this.babOrder,
    required this.createdAt,
  });

  factory BabDetail.fromJson(Map<String, dynamic> json) {
    return BabDetail(
      babId: json['bab_id'].toString(),
      amalanId: json['amalan_id'].toString(),
      babTitle: json['bab_title'],
      babOrder: json['bab_order'].toString(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class IsiContent {
  final String isiId;
  final String babId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  IsiContent({
    required this.isiId,
    required this.babId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IsiContent.fromJson(Map<String, dynamic> json) {
    return IsiContent(
      isiId: json['isi_id'].toString(),
      babId: json['bab_id'].toString(),
      content: json['isi_content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class IsiBabResponse {
  final bool status;
  final String message;
  final BabDetail babDetail;
  final IsiContent isiContent;

  IsiBabResponse({
    required this.status,
    required this.message,
    required this.babDetail,
    required this.isiContent,
  });

  factory IsiBabResponse.fromJson(Map<String, dynamic> json) {
    return IsiBabResponse(
      status: json['status'],
      message: json['message'] ?? '',
      babDetail: BabDetail.fromJson(json['data']['bab_detail']),
      isiContent: IsiContent.fromJson(json['data']['isi_content']),
    );
  }
}