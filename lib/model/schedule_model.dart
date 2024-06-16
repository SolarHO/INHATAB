import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'package:time_planner/time_planner.dart';
import '../widget/schedule_widget.dart' show ScheduleWidget, TaskBottomSheet;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ScheduleModel extends FlutterFlowModel<ScheduleWidget> {
  /// State fields for stateful widgets in this page.
  final unfocusNode = FocusNode();
  final user = FirebaseAuth.instance.currentUser;
  //현재 로그인된 사용자 가져오기(uid)
  final databaseReference = FirebaseDatabase.instance.reference();

  Function? onTasksUpdated;

  @override
  void initState(BuildContext context) {}

  Future addTasks(List<Map<String, dynamic>> newTasks) async {
    if (user != null) {
      // 계정 정보를 이용해 해당 유저의 uid로 시간표 정보를 가져옴
      DatabaseEvent event = await databaseReference.child('tasks/${user!.uid}').once();
      DataSnapshot snapshot = event.snapshot;

      // 만약 데이터가 없다면, 빈 시간표 데이터를 먼저 추가
      if (snapshot.value == null) {
        await databaseReference.child('tasks/${user!.uid}').push().set({
          'className': '',
          'professorName': '',
          'day': '',
          'startTime': DateTime.now().toIso8601String(),
          'endTime': DateTime.now().toIso8601String(),
          'location': '',
          'color': 0xFFFFFFFF,
        });
      }

      for (var task in newTasks) {
        var className = task['className'];
        var professorName = task['professorName'];
        var day = task['day'];
        var startTime = task['startTime'];
        var endTime = task['endTime'];
        var location = task['location'];
        var color = task['color'].value;

        // 시간표 정보를 저장
        await databaseReference.child('tasks/${user!.uid}').push().set({
          'className': className,
          'professorName': professorName,
          'day': day,
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'location': location,
          'color' : color,
        });
      }
    } else {
      print('알 수 없는 오류가 발생되었습니다.'); // 로그인 되어 있지 않는 경우 에러메시지
    }
  }

  Future editTasks(List<Map<String, dynamic>> updatedTasks) async {
    for (var task in updatedTasks) {
      var key = task['Tkey'];
      var className = task['className'];
      var professorName = task['professorName'];
      var day = task['day'];
      var startTime = task['startTime'];
      var endTime = task['endTime'];
      var location = task['location'];
      var color = task['color'].value;

      if (user != null) {
        await databaseReference.child('tasks/${user!.uid}/$key').set({
          'className': className,
          'professorName': professorName,
          'day': day,
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'location': location,
          'color' : color,
        });
      } else {
        print('알 수 없는 오류가 발생되었습니다.'); // 로그인 되어 있지 않는 경우 에러메시지
      }
    }
  }

  Future<void> deleteTask(String key) async {
    // Firebase Realtime Database에서 해당 task 데이터 삭제
    await databaseReference.child('tasks/${user!.uid}/$key').remove();
  }

  int _convertDayToIndex(String day) {
    switch (day) {
      case '월':
        return 0;
      case '화':
        return 1;
      case '수':
        return 2;
      case '목':
        return 3;
      case '금':
        return 4;
      default:
        return 0; 
    }
  }

  late BuildContext context;

  Future<List<TimePlannerTask>> loadTasks() async {
    DatabaseEvent event = await databaseReference.child('tasks/${user!.uid}').once();
    DataSnapshot snapshot = event.snapshot;
    Map<dynamic, dynamic> tasksMap = snapshot.value as Map<dynamic, dynamic>;
    List<TimePlannerTask> loadedTasks = [];

    tasksMap.forEach((key, value) {
      var className = value['className'];
      var professorName = value['professorName'];
      var day = value['day'];
      var startTime = DateTime.parse(value['startTime']).add(Duration(hours: 1));
      var endTime = DateTime.parse(value['endTime']).add(Duration(hours: 1));
      var location = value['location'];
      var colorValue = value['color'] ?? 0xFFFFFFFF; // 색상 정보가 null인 경우 기본 색상을 사용
      var hexColor = colorValue.toRadixString(16).padLeft(8, '0'); // int 값을 16진수 문자열로 변환
      var color = Color(int.parse(hexColor, radix: 16));

      var newTask = TimePlannerTask(
        color: color, //시간표 셀 색상
        dateTime: TimePlannerDateTime(
          day: _convertDayToIndex(day),
          hour: startTime.hour,
          minutes: startTime.minute,
        ),
        minutesDuration: endTime.difference(startTime).inMinutes,
        daysDuration: 1,
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return TaskBottomSheet(
                model: this,
                Tkey: key,
                className: className,
                professorName: professorName,
                day: day,
                startTime: startTime.add(Duration(hours: -1)),
                endTime: endTime.add(Duration(hours: -1)),
                location: location,
                color: color,
              );
            },
          ).then((_) {
            onTasksUpdated?.call();
          });
        },
        child: Text(
          '$className\n$location',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      );

      loadedTasks.add(newTask);
    });

    return loadedTasks;
  }

  @override
  void dispose() {
    unfocusNode.dispose();
  }
}
