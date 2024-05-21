import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'package:flutter/material.dart';
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
  final scrollController = ScrollController();

  List<String> _postTitles = []; //게시글 제목
  List<String> _postIds = []; // 게시글의 ID를 저장할 리스트 추가
  List<int> _likeCounts = []; //게시글 좋아요 수
  List<int> _commentCounts = []; //게시글 좋아요 수
  List<String> _timestamps = []; //게시글 작성 시간

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BbsModel());
    _fetchPosts();
    _fetchSelectedBoard();
    scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _model.dispose();
    scrollController.dispose();
    super.dispose();
  }

  _scrollListener() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange) {
      _fetchPosts(); // 스크롤이 최하단에 도달하면 게시글 불러오기
    }
  }

  Future<void> _fetchSelectedBoard() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedBoard = prefs.getString('selectedBoard') ?? ''; // 선택된 게시판 가져오기
    });
  }

  int _limit = 15; //한번에 불러올 게시글 제한 15개
  String? _lastKey; //마지막으로 불러온 글의 Key

  Future<void> _fetchPosts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedBoard = prefs.getString('selectedBoard');
    if (selectedBoard == null) {
      throw Exception('게시판을 선택하지 않았습니다.');
    }
    try {
      DatabaseReference postRef = FirebaseDatabase.instance.reference().child(
          'boardinfo').child('boardstat').child(selectedBoard);
      Query query = postRef.orderByKey();

      // _lastKey가 있으면 _lastKey 이전의 게시글을 불러옴
      if (_lastKey != null) {
        query = query.endBefore(_lastKey);
      }

      // 가장 최근의 _limit개의 게시글을 불러옴
      query = query.limitToLast(_limit);

      DatabaseEvent event = await query.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        Map<dynamic, dynamic>? posts = snapshot.value as Map<dynamic, dynamic>?;

        if (posts != null) {
          var reversedPosts = posts.entries.toList()
            ..sort((a, b) => b.key.compareTo(a.key));

          // _lastKey 업데이트
          String newLastKey = reversedPosts.last.key;

          //처음 작성된 게시글을 불러왔으면 새로고침 중단 
          if (_lastKey == newLastKey) {
            return;
          }

          _lastKey = newLastKey;

          reversedPosts.forEach((entry) {
            String? title = entry.value['title'];
            String? postId = entry.key;
            String? timestamp = entry.value['timestamp'];
            int? likeCount = entry.value['likecount']; // 조아요수
            int? commentCount = entry.value['commentcount']; // 댓글수
            if (title != null && postId != null) {
              setState(() {
                _postTitles.add(title);
                _postIds.add(postId);
                _timestamps.add(timestamp!);
                _likeCounts.add(likeCount ?? 0);
                _commentCounts.add(commentCount ?? 0);
              });
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
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
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
            icon: Icon(Icons.arrow_back, color: Colors.white,), // 뒤로가기 아이콘
            onPressed: () {
              GoRouter.of(context).go('/Bbs'); // 게시판화면으로이동
            },
          ),
          actions: [
            Container(
              margin: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: IconButton(
                icon: Icon(Icons.add_rounded, size: 30, color: Colors.white),
                onPressed: () {
                  GoRouter.of(context).go('/WriteBoardPage');
                },
              ),
            ),
          ],
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
                  alignment: AlignmentDirectional(0, -1),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: EdgeInsets.zero,
                          itemCount: _postTitles.length,
                          separatorBuilder: (context, index) => Divider(color: Colors.grey),
                          itemBuilder: (context, index) {
                            return InkWell(
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _postTitles[index],
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 4), // 간격 추가
                                    Row(
                                      children: [
                                        Icon(Icons.thumb_up_alt, size: 12, color: Colors.blue),
                                        Text(
                                          ' ${_likeCounts[index]}', style: TextStyle(fontSize: 12, color: Colors.blue)), // 좋아요
                                        Icon(Icons.mode_comment_rounded, size: 12, color: Colors.green),
                                        Text(
                                          ': ${_commentCounts[index]} ', style: TextStyle(fontSize: 12, color: Colors.green)), //댓글
                                        Text('${_timestamps[index]}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      ]
                                    ),
                                  ],
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
      ),
    );
  }
}