import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterflow_ui/flutterflow_ui.dart';
import '../widget/schedule_widget.dart' show ScheduleWidget;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';

class ScheduleModel extends FlutterFlowModel<ScheduleWidget> {
  /// State fields for stateful widgets in this page.
  final unfocusNode = FocusNode();
  final user = FirebaseAuth.instance.currentUser;
  //현재 로그인된 사용자 가져오기(uid)

  @override
  void initState(BuildContext context) {}

  void addTask(String className, int startHour, int endHour) {
    // 현재 사용자의 uid를 가져옵니다.
    final String uid = user!.uid;
    // Firebase Realtime Database의 'users' 경로에 현재 사용자의 정보를 저장합니다.
    final dbRef = FirebaseDatabase.instance.reference();
    dbRef.child('users').child(uid).child('tasks').push().set({
      'className': className,
      'startHour': startHour,
      'endHour': endHour,
    });
  }

  @override
  void dispose() {
    unfocusNode.dispose();
  }
}
