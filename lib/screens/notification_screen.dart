import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [
    {
      "title": "Tagihan Baru",
      "description": "Tagihan SPP bulan ini telah diterbitkan.",
      "date": DateTime.now().subtract(Duration(hours: 2)),
      "icon": Icons.payment,
      "isRead": false,
    },
    {
      "title": "Izin Disetujui",
      "description": "Izin keluar pada 10 Februari 2025 telah disetujui.",
      "date": DateTime.now().subtract(Duration(days: 1)),
      "icon": Icons.check_circle,
      "isRead": true,
    },
    {
      "title": "Pengumuman",
      "description": "Libur semester akan dimulai pada 20 Februari 2025.",
      "date": DateTime.now().subtract(Duration(days: 3)),
      "icon": Icons.campaign,
      "isRead": true,
    },
  ];

  void _removeNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifikasi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 10),
                  Text(
                    "Tidak ada notifikasi baru",
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => Divider(thickness: 1, color: Colors.grey[300]),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: Key(notification["title"]),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _removeNotification(index);
                  },
                  background: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    color: Colors.red,
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: notification["isRead"] ? Colors.grey[300] : Colors.teal,
                          child: Icon(notification["icon"], color: Colors.white, size: 28),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification["title"],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                notification["description"],
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              ),
                              SizedBox(height: 6),
                              Text(
                                DateFormat('dd MMM yyyy, HH:mm').format(notification["date"]),
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            notification["isRead"] ? Icons.done_all : Icons.fiber_manual_record,
                            color: notification["isRead"] ? Colors.teal : Colors.red,
                            size: notification["isRead"] ? 20 : 12,
                          ),
                          onPressed: () {
                            setState(() {
                              notifications[index]["isRead"] = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
