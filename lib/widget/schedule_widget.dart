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
    _model.onTasksUpdated = loadTasks;
    loadTasks();
    _model.context = context;
  }

  Future<void> loadTasks() async {
    List<TimePlannerTask> loadedTasks = await _model.loadTasks();
    setState(() {
      tasks = loadedTasks;
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }
  

  List<TimePlannerTask> tasks = [];
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
          actions: [
            Container(
              margin: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 104, 97, 232),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: IconButton(
                icon: Icon(Icons.add, color: Colors.white),
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
                      body: TaskInputBottomSheet(model: _model),
                    ),
                  ).then((_) {
                    loadTasks();
                  });
                },
              ),
            ),
          ],
          centerTitle: false,
          elevation: 2,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = constraints.maxWidth * 0.16; //셀 너비 조정
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
                cellHeight: 60,
                showScrollBar: false,
              ),
              tasks: tasks, // 여기에 작업 목록을 넣으세요.
            );
          },
        ),
      ),
    );
  }
}

class TaskInputBottomSheet extends StatefulWidget {
  final ScheduleModel model;
  final List<Map<String, dynamic>> initialTasks; // 초기 시간표 정보를 전달하는 매개변수를 추가합니다.

  TaskInputBottomSheet({required this.model, this.initialTasks = const []}); // 기본값을 빈 리스트로 설정합니다.
  @override
  _TaskInputBottomSheetState createState() => _TaskInputBottomSheetState();
}

class _TaskInputBottomSheetState extends State<TaskInputBottomSheet> {
  //시간표 저장 바텀시트 위젯
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    // 초기 작업 입력 필드 추가
    if (widget.initialTasks.isEmpty) {
      // 초기 작업 입력 필드 추가
      DateTime now = DateTime.now();
      tasks.add({
        'className': '',
        'professorName': '',
        'day': '월',
        'startTime': DateTime(now.year, now.month, now.day, 9, 0),
        'endTime': DateTime(now.year, now.month, now.day, 10, 0),
        'location': '',
      });
    } else {
      tasks = List<Map<String, dynamic>>.from(widget.initialTasks); // 초기 시간표 정보를 사용하여 상태를 설정합니다.
    }
  }
  Future<void> _selectTime(BuildContext context, int index, String type) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(tasks[index][type]),
    );
    if (picked != null) {
      DateTime newTime = DateTime(
        tasks[index][type].year,
        tasks[index][type].month,
        tasks[index][type].day,
        picked.hour,
        picked.minute,
      );

      if (type == 'startTime' && newTime.isAtSameMomentAs(tasks[index]['endTime']) || newTime.isAfter(tasks[index]['endTime'])) {
        // 시작 시간이 종료 시간보다 늦거나 같은 경우, 종료 시간을 시작 시간보다 한시간 뒤로 설정
        tasks[index]['endTime'] = newTime.add(Duration(hours: 1));
      } else if (type == 'endTime' && newTime.isAtSameMomentAs(tasks[index]['startTime']) || newTime.isBefore(tasks[index]['startTime'])) {
        // 종료 시간이 시작 시간보다 빠르거나 같은 경우, 시작 시간을 종료 시간보다 한시간 빠르게 설정
        tasks[index]['startTime'] = newTime.subtract(Duration(hours: 1));
      }

      setState(() {
        tasks[index][type] =newTime;
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
                  controller: TextEditingController(text: task['className']), // 초기값 설정
                  onChanged: (value) => setState(() => tasks[index]['className'] = value),
                  decoration: InputDecoration(labelText: '수업명'),
                ),
                TextField(
                  controller: TextEditingController(text: task['professorName']), // 초기값 설정
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0), // 원하는 패딩 값을 설정합니다.
                  child: TextField(
                    controller: TextEditingController(text: task['location']), // 초기값 설정
                    onChanged: (value) => setState(() => tasks[index]['location'] = value),
                    decoration: InputDecoration(labelText: '장소'),
                  ),
                ),
              ],
            );
          }).toList(),
          ElevatedButton(
            onPressed: () async {
              //수업명이 입력되었는지 확인
              for (var task in tasks) {
                if (task['className'].isEmpty) {
                  // 수업명이 입력되지 않은 경우, 알림을 표시하고 함수를 종료
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('수업명을 입력해주세요.')),
                  );
                  return;
                }
                if (task['startTime'].hour < 9 || task['endTime'].hour > 23 || task['startTime'].hour == 0 || task['endTime'].hour == 0) {
                  // 시간대가 범위를 벗어나는 경우, 하단 스냅바를 표시하고 함수를 종료
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('수업시간은 09:00부터 23:00 사이여야 합니다.')),
                  );
                  return;
                }
              }
              
              if (widget.initialTasks.isEmpty) {
              // 초기 시간표 정보가 없는 경우, addTasks를 호출합니다.
                await widget.model.addTasks(tasks);
              } else {
              // 초기 시간표 정보가 있는 경우, editTasks를 호출합니다.
                await widget.model.editTasks(tasks);
              }
              Navigator.pop(context);
            },
            child: Text('저장'),
          ),
        ],
      ),
    );
  }
}

class TaskBottomSheet extends StatefulWidget {
  final ScheduleModel model;
  final String Tkey;
  final String className;
  final String professorName;
  final String day;
  final DateTime startTime;
  final DateTime endTime;
  final String location;

  TaskBottomSheet({
    required this.model,
    required this.Tkey,
    required this.className,
    required this.professorName,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.location,
  });

  @override
  _TaskBottomSheetState createState() => _TaskBottomSheetState();
}

class _TaskBottomSheetState extends State<TaskBottomSheet> {
  //시간표 정보 바텀시트 위젯
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16, 0, 0, 0),
            child: Text(
              '${widget.className}',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: Color(0xFF14181B),
                fontSize: 24,
                letterSpacing: 0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16, 4, 0, 8),
            child: Text(
              '${widget.professorName}\n${widget.location}\n${widget.day} ${DateFormat('HH:mm').format(widget.startTime)} - ${DateFormat('HH:mm').format(widget.endTime)}',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: Color(0xFF57636C),
                fontSize: 14,
                letterSpacing: 0,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          InkWell( // InkWell 위젯 추가
            onTap: () async { // 클릭 이벤트 추가
              await showModalBottomSheet(
                context: context,
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back), // 뒤로가기 아이콘 추가
                      onPressed: () => Navigator.pop(context), // 아이콘을 누르면 BottomSheet 닫힘
                    ),
                    title: Text('수업 정보 수정'),
                  ),
                  body: TaskInputBottomSheet(
                    model: ScheduleModel(),
                    initialTasks: [{
                      'Tkey': widget.Tkey,
                      'className': widget.className,
                      'professorName': widget.professorName,
                      'day': widget.day,
                      'startTime': widget.startTime,
                      'endTime': widget.endTime,
                      'location': widget.location,
                    }],
                  ),
                ),
              );
              Navigator.pop(context);
            },
            child: Container(
              width: double.infinity,
              height: 60,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Card(
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      color: Color(0xFFF1F4F8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.mode_edit,
                          color: Color(0xFF57636C),
                          size: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(12, 0, 0, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '수정',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                color: Color(0xFF14181B),
                                fontSize: 16,
                                letterSpacing: 0,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          InkWell( // InkWell 위젯 추가
            onTap: () async { // 클릭 이벤트 추가
              // Firebase Realtime Database에서 해당 task 데이터 삭제
              await widget.model.deleteTask(widget.Tkey);
              Navigator.pop(context); // BottomSheet 닫기
            },
            child: Container(
              width: double.infinity,
              height: 60,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Card(
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      color: Color(0xFFF1F4F8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.delete_outline,
                          color: Color(0xFF57636C),
                          size: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(12, 0, 0, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '삭제',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                color: Color(0xFF14181B),
                                fontSize: 16,
                                letterSpacing: 0,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
