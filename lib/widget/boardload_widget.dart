import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../model/bbs_model.dart';
export '../model/bbs_model.dart';
import 'package:INHATAB/PostDetail.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
class BoardloadWidget extends StatefulWidget {
  const BoardloadWidget({Key? key}) : super(key: key);

  @override
  State<BoardloadWidget> createState() => _BoardloadWidgetState();
}

class _BoardloadWidgetState extends State<BoardloadWidget> {
  late BbsModel _model;
  String selectedBoard = ''; // 추가된 부분
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<String> _postTitles = [];
  List<String> _postIds = []; // 게시글의 ID를 저장할 리스트 추가

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BbsModel());
    _fetchPosts();
    _fetchSelectedBoard();
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _fetchSelectedBoard() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedBoard = prefs.getString('selectedBoard') ?? ''; // 선택된 게시판 가져오기
    });
  }

  Future<void> _fetchPosts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();  //게시판항목값을 세션으로 계속 받아옴 뒤에도 계속 활용함
    String? selectedBoard = prefs.getString('selectedBoard');
    if (selectedBoard == null) {
      throw Exception('게시판을 선택하지 않았습니다.');
    }
    try {
      DatabaseReference postRef = FirebaseDatabase.instance.reference().child(
          'boardinfo').child('boardstat').child(selectedBoard);
      DatabaseEvent event = await postRef.limitToLast(10).once();
      DataSnapshot snapshot = event.snapshot;

      // 반환된 값이 null인지 체크
      if (snapshot.value != null) {
        // 반환된 값이 'Object?' 유형이므로 'Map<dynamic, dynamic>'으로 캐스팅
        Map<dynamic, dynamic>? posts = snapshot.value as Map<dynamic, dynamic>?;

        if (posts != null) {
          posts.forEach((key, value) {
            // value가 null인지 체크
            if (value != null && value is Map<dynamic, dynamic>) {
              String? title = value['title']; // 제목 가져오기
              String? postId = key; // 게시글의 ID 가져오기
              if (title != null && postId != null) {
                setState(() {
                  _postTitles.add(title); // 가져온 제목을 리스트에 추가
                  _postIds.add(postId); // 가져온 게시글 ID를 리스트에 추가
                });
              }
            }
          });
        }
      }
    } catch (error) {
      print("게시글 정보를 가져오는 데 실패했습니다: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0x4C181BF8),
        appBar: AppBar(
          backgroundColor: Color(0x4C181BF8),
          title: Text(
            selectedBoard.isNotEmpty ? selectedBoard : '게시판',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
              fontFamily: 'Outfit',
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 0,
            ),
          ),
          automaticallyImplyLeading: false, // 뒤로가기 버튼 자동 생성 비활성화
          leading: IconButton( // 왼쪽에 아이콘 추가
            icon: Icon(Icons.arrow_back), // 뒤로가기 아이콘
            onPressed: () {
              GoRouter.of(context).go('/Bbs'); // 게시판화면으로이동
            },
          ),
          actions: [],
          centerTitle: false,
          elevation: 2,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        FlutterFlowTheme.of(context).alternate,
                        FlutterFlowTheme.of(context).secondaryText,
                      ],
                      stops: [0, 1],
                      begin: AlignmentDirectional(0.87, -1),
                      end: AlignmentDirectional(-0.87, 1),
                    ),
                  ),
                  alignment: AlignmentDirectional(0, -1),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _postTitles.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                // 클릭한 게시물의 ID를 전달하여 상세화면으로 이동
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PostDetailPage(postId: _postIds[index]),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 20),
                                margin: EdgeInsets.symmetric(vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _postTitles[index],
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            GoRouter.of(context).go('/WriteBoardPage');
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}