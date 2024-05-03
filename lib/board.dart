import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';
import 'package:INHATAB/PostDetail.dart';

class BoardPage extends StatefulWidget {
  @override
  _BoardPageState createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  List<String> _postTitles = [];
  List<String> _postIds = []; // 게시글의 ID를 저장할 리스트 추가

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      DatabaseReference postRef = FirebaseDatabase.instance.reference().child('boardinfo');
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
    return Scaffold(
      appBar: AppBar(
        title: Text('게시판'),
      ),
      body: ListView.builder(
        itemCount: _postTitles.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_postTitles[index]),
            onTap: () {
              // 선택한 게시글의 ID를 PostDetailPage로 전달하여 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailPage(postId: _postIds[index]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          GoRouter.of(context).go('/WriteBoardPage');
        },
        child: Icon(Icons.add),
      ),
    );
  }
}