import 'package:intl/intl.dart';

class TransactionResponse {
  final Meta meta;
  final Summary summary;
  final List<Transaction> transactions;

  TransactionResponse({
    required this.meta,
    required this.summary,
    required this.transactions,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    return TransactionResponse(
      meta: Meta.fromJson(json['data']['meta']),
      summary: Summary.fromJson(json['data']['summary']),
      transactions: List<Transaction>.from(
          json['data']['transactions'].map((x) => Transaction.fromJson(x))),
    );
  }
}

class Meta {
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final int totalItems;

  Meta({
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.totalItems,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      currentPage: json['current_page'],
      totalPages: json['total_pages'],
      itemsPerPage: json['items_per_page'],
      totalItems: json['total_items'],
    );
  }
}

class Summary {
  final int totalPaid;
  final int totalBill;
  final int outstandingBalance;

  Summary({
    required this.totalPaid,
    required this.totalBill,
    required this.outstandingBalance,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      totalPaid: json['total_paid'],
      totalBill: json['total_bill'],
      outstandingBalance: json['outstanding_balance'],
    );
  }
}

class Transaction {
  final String transactionId;
  final String paymentType;
  final String paymentName;
  final String period;
  final int amount;
  final DateTime transactionDate;
  final String status;
  final Details details;

  Transaction({
    required this.transactionId,
    required this.paymentType,
    required this.paymentName,
    required this.period,
    required this.amount,
    required this.transactionDate,
    required this.status,
    required this.details,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId: json['transaction_id'],
      paymentType: json['payment_type'],
      paymentName: json['payment_name'],
      period: json['period'],
      amount: json['amount'],
      transactionDate: DateTime.parse(json['transaction_date']),
      status: json['status'],
      details: Details.fromJson(json['details']),
    );
  }

  String get formattedDate {
    return DateFormat('dd MMM yyyy HH:mm').format(transactionDate);
  }

  String get formattedAmount {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount);
  }
}

class Details {
  final String? month;
  final String receiptNumber;
  final String description;

  Details({
    this.month,
    required this.receiptNumber,
    required this.description,
  });

  factory Details.fromJson(Map<String, dynamic> json) {
    return Details(
      month: json['month'],
      receiptNumber: json['receipt_number'],
      description: json['description'],
    );
  }
}