import 'package:flutterflow_ui/flutterflow_ui.dart';
import '../widget/alert_widget.dart' show AlertWidget;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
class AlertModel extends ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  final unfocusNode = FocusNode();

  @override
  void initState() {}

  @override
  void dispose() {
    unfocusNode.dispose();
    super.dispose();
  }

  Future<void> fetchNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null) {
      throw Exception('사용자 ID를 찾을 수 없습니다.');
    }

    DatabaseReference alertRef = FirebaseDatabase.instance.reference().child('alerts').child(userId);
    DataSnapshot snapshot = await alertRef.once().then((event) => event.snapshot);

    if (snapshot.value != null) {
      Map<dynamic, dynamic> alertsData = snapshot.value as Map<dynamic, dynamic>;
      _notifications = alertsData.values.map((e) => Map<String, dynamic>.from(e)).toList();

      // 알림을 시간순으로 정렬
      _notifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      notifyListeners();
    }
  }
}