import 'package:INHATAB/model/userModel.dart';
import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/BoardModel.dart';
import 'package:INHATAB/PostDetail.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../writeboard.dart';
class BoardloadWidget extends StatefulWidget {
  const BoardloadWidget({Key? key}) : super(key: key);

  @override
  State<BoardloadWidget> createState() => _BoardloadWidgetState();
}

class _BoardloadWidgetState extends State<BoardloadWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController(); //검색컨트롤러

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
    Provider.of<userModel>(context, listen: false).fetchUser();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  _scrollListener() async {
    if (scrollController.offset >= scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          Provider.of<BoardModel>(context, listen: false).fetchPosts(); // 스크롤이 최하단에 도달하면 게시글 불러오기
    }
  }

  void showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('검색'),
          content: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: '검색어를 입력하세요',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String query = searchController.text.trim();
                if (query.isNotEmpty) {
                  Provider.of<BoardModel>(context, listen: false).clear();
                  Provider.of<BoardModel>(context, listen: false).fetchPosts(query: query);
                }
                Navigator.pop(context);
              },
              child: Text('검색'),
            ),
            TextButton(
              onPressed: () {
                searchController.clear();
                Provider.of<BoardModel>(context, listen: false).clearSearch();
                Navigator.pop(context);
              },
              child: Text('취소'),
            ),
          ],
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    return Consumer<BoardModel>(
      builder: (context, value, child) {
        return GestureDetector(
          onTap: () => value.unfocusNode.canRequestFocus
              ? FocusScope.of(context).requestFocus(value.unfocusNode)
              : FocusScope.of(context).unfocus(),
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: AppBar(
              backgroundColor: Color(0x4C181BF8),
              title: Text(
                Provider.of<BoardModel>(context).selectedBoard.toString(),
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
                  Provider.of<BoardModel>(context, listen: false).clear();
                  GoRouter.of(context).go('/Bbs'); // 게시판화면으로이동
                },
              ),
              actions: [

            IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearchDialog(context);

            },
          ),
                Container(
                  margin: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.add_rounded, size: 30, color: Colors.white),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WriteBoardPage()),
                      );
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
                              itemCount: Provider.of<BoardModel>(context).postTitles.length,
                              separatorBuilder: (context, index) => Divider(color: Colors.grey),
                              itemBuilder: (context, index) {
                                return InkWell(
                                  onTap: () {
                                    // 클릭한 게시물의 ID를 전달하여 상세화면으로 이동
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PostDetailPage(postId: Provider.of<BoardModel>(context).postIds[index]),
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
                                          Provider.of<BoardModel>(context).postTitles[index],
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        SizedBox(height: 4), // 간격 추가
                                        Row(
                                          children: [
                                            Text('${Provider.of<BoardModel>(context).name[index]} ', style: TextStyle(fontSize: 12, color: Colors.black)),
                                            Text('/ ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                            if (Provider.of<BoardModel>(context).likeCounts[index] > 0) ...[
                                              Icon(Icons.thumb_up_alt, size: 12, color: Colors.blue),
                                              Text(': ${Provider.of<BoardModel>(context).likeCounts[index]} ', style: TextStyle(fontSize: 12, color: Colors.blue)),
                                              Text('/ ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                            ],
                                            if (Provider.of<BoardModel>(context).commentCounts[index] > 0) ...[
                                              Icon(Icons.mode_comment_rounded, size: 12, color: Colors.green),
                                              Text(': ${Provider.of<BoardModel>(context).commentCounts[index]} ', style: TextStyle(fontSize: 12, color: Colors.green)),
                                              Text('/ ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                            ],
                                            Text('${Provider.of<BoardModel>(context).timestamps[index]}  ', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
      },
    );
  }
}
