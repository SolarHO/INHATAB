import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'package:flutter/material.dart';
import 'package:time_planner/time_planner.dart';

import '../model/schedule_model.dart';
export '../model/schedule_model.dart';

class ScheduleWidget extends StatefulWidget {
  const ScheduleWidget({super.key});

  @override
  State<ScheduleWidget> createState() => _ScheduleWidgetState();
}

class _ScheduleWidgetState extends State<ScheduleWidget> {
  late ScheduleModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ScheduleModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  List<TimePlannerTask> tasks = [
    TimePlannerTask(
      // background color for task
      color: Color.fromARGB(255, 11, 61, 122),
      // day: Index of header, hour: Task will be begin at this hour
      // minutes: Task will be begin at this minutes
      dateTime: TimePlannerDateTime(day: 2, hour: 13, minutes: 35),
      // Minutes duration of taskd
      minutesDuration: 100,
      // Days duration of task (use for multi days task)
      daysDuration: 1,
      onTap: () {},
      child: Text(
        'Start-Up\n4-401',
        style: TextStyle(color: Colors.grey[350], fontSize: 12),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: Color(0x4C181BF8),
          automaticallyImplyLeading: false,
          title: Text(
            '시간표',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: 0,
                ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 2,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = constraints.maxWidth * 0.16; // 17% of container width
            return TimePlanner(
              startHour: 9,
              endHour: 23,
              setTimeOnAxis: false,
              use24HourFormat: true,
              headers: [
                TimePlannerTitle(title: "월"),
                TimePlannerTitle(title: "화"),
                TimePlannerTitle(title: "수"),
                TimePlannerTitle(title: "목"),
                TimePlannerTitle(title: "금"),
              ],
              style: TimePlannerStyle(
                cellWidth: cellWidth.toInt(),
                showScrollBar: false,
              ),
              tasks: tasks, // 여기에 작업 목록을 넣으세요.
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back), // 뒤로가기 아이콘 추가
                    onPressed: () => Navigator.pop(context), // 아이콘을 누르면 BottomSheet 닫힘
                  ),
                  title: Text('수업 추가'),
                ),
                body: TaskInputBottomSheet(),
              ),
            );
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

class TaskInputBottomSheet extends StatefulWidget {
  @override
  _TaskInputBottomSheetState createState() => _TaskInputBottomSheetState();
}

class _TaskInputBottomSheetState extends State<TaskInputBottomSheet> {
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    // 초기 작업 입력 필드 추가
    tasks.add({
      'className': '',
      'professorName': '',
      'day': '월',
      'startTime': DateTime.now(),
      'endTime': DateTime.now(),
      'location': '',
    });
  }

  void addNewTaskField() {
    setState(() {
      tasks.add({
        'className': '',
        'professorName': '',
        'day': '월',
        'startTime': DateTime.now(),
        'endTime': DateTime.now(),
        'location': '',
      });
    });
  }

  Future<void> _selectTime(BuildContext context, int index, String type) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(tasks[index][type]),
    );
    if (picked != null) {
      setState(() {
        tasks[index][type] = DateTime(
          tasks[index][type].year,
          tasks[index][type].month,
          tasks[index][type].day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: ListView(
        children: [
          ...tasks.map((task) {
            int index = tasks.indexOf(task);
            return Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => tasks[index]['className'] = value),
                  decoration: InputDecoration(labelText: '수업명'),
                ),
                TextField(
                  onChanged: (value) => setState(() => tasks[index]['professorName'] = value),
                  decoration: InputDecoration(labelText: '교수명'),
                ),
                Row(
                  children: [
                    DropdownButton(
                      value: task['day'],
                      items: ['월', '화', '수', '목', '금']
                          .map((day) => DropdownMenuItem(value: day, child: Text('$day요일')))
                          .toList(),
                      onChanged: (value) => setState(() => tasks[index]['day'] = value),
                    ),
                    TextButton(
                      onPressed: () => _selectTime(context, index, 'startTime'),
                      child: Text(DateFormat('HH:mm').format(tasks[index]['startTime'])),
                    ),
                    TextButton(
                      onPressed: () => _selectTime(context, index, 'endTime'),
                      child: Text(DateFormat('HH:mm').format(tasks[index]['endTime'])),
                    ),
                  ],
                ),
                TextField(
                  onChanged: (value) => setState(() => tasks[index]['location'] = value),
                  decoration: InputDecoration(labelText: '장소'),
                ),
                if (index == tasks.length - 1)
                  TextButton(
                    onPressed: addNewTaskField,
                    child: Text('시간 및 장소 추가'),
                  ),
              ],
            );
          }).toList(),
          ElevatedButton(
            onPressed: () {
              // 여기에 Firebase Realtime Database 저장 로직 추가
            },
            child: Text('저장'),
          ),
        ],
      ),
    );
  }
}
