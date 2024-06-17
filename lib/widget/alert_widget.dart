import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/alert_model.dart';
export '../model/alert_model.dart';
import 'package:provider/provider.dart';
class AlertWidget extends StatefulWidget {
  const AlertWidget({super.key});

  @override
  State<AlertWidget> createState() => _AlertWidgetState();
}

class _AlertWidgetState extends State<AlertWidget> {
  late AlertModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = AlertModel();
    _model.fetchNotifications(); // 알림 데이터를 가져옴
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AlertModel>(
      create: (_) => _model,
      child: Consumer<AlertModel>(
        builder: (context, alertModel, child) {
          return GestureDetector(
            onTap: () => _model.unfocusNode.canRequestFocus
                ? FocusScope.of(context).requestFocus(_model.unfocusNode)
                : FocusScope.of(context).unfocus(),
            child: Scaffold(
              key: scaffoldKey,
              backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
              appBar: AppBar(
                title: Text(
                  '알림',
                  style: Theme.of(context).textTheme.headline6!.copyWith(
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Color(0x4C181BF8),
              ),
              body: SafeArea(
                top: true,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: alertModel.notifications.length,
                        itemBuilder: (context, index) {
                          // 최신 알림이 위로 오도록 역순으로 접근
                          final notification = alertModel.notifications[index];
                          return ListTile(
                            title: Text(notification['message']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notification['chatMessage'] ?? ''),
                                SizedBox(height: 4), // 간격 추가
                                Text(
                                  notification['timestamp'],
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (context, index) {
                          return Divider(height: 1, thickness: 1);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}