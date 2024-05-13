import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;

  const PostDetailPage({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late DatabaseReference postRef;

  bool liked = false;
  int likeCount = 0; // 좋아요 수를 저장하는 변수 추가

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      String? selectedBoard = prefs.getString('selectedBoard');
      if (selectedBoard == null) {
        throw Exception('게시판을 선택하지 않았습니다.');
      }
      postRef = FirebaseDatabase.instance
          .reference()
          .child('boardinfo')
          .child('boardstat')
          .child(selectedBoard)
          .child(widget.postId)
          .child('contents');

      // 좋아요 수를 가져와서 변수에 저장
      _fetchLikeCount();
    });
  }

  Future<void> _fetchLikeCount() async {
    try {
      DatabaseEvent event = await postRef.once();
      DataSnapshot snapshot = event.snapshot;

      Map postData = snapshot.value as Map;
      setState(() {
        likeCount = postData['likecount'] ?? 0;
      });
    } catch (error) {
      print("좋아요 수를 가져오는 도중 오류 발생: $error");
    }
  }


  Future<void> _likePost() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null) {
      throw Exception('사용자 ID를 찾을 수 없습니다.');
    }

    try {
      // 사용자의 like 노드에 postid를 추가합니다.
      DatabaseReference userRef = FirebaseDatabase.instance.reference().child(
          'users').child(userId);
      DatabaseEvent event = await userRef.child('like')
          .child(widget.postId)
          .once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value == null) {
        // 좋아요를 누른 적이 없는 경우에만 실행합니다.
        await postRef.child('likecount').set(ServerValue.increment(1));
        await userRef.child('like').child(widget.postId).set(true);
        await _fetchLikeCount(); // 좋아요 누를 때마다 좋아요 수 다시 가져오기
      } else {
        // 이미 눌렀다면 다이얼로그 창을 띄웁니다.
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('이미 좋아요를 눌렀습니다.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('확인'),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      print("좋아요를 추가하는 데 실패했습니다: $error");
      throw error;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시글 상세 정보'),
      ),
      body: FutureBuilder(
        future: _fetchPostDetails(),
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('게시글을 불러오는 동안 오류가 발생했습니다.'));
          } else if (snapshot.hasData) {
            // 데이터를 가져와서 UI에 표시
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snapshot.data!['title'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '작성 시간: ${snapshot.data!['timestamp']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 16),
                  // 이미지를 보여주는 위젯 추가
                  if (snapshot.data!['imageUrl'] != null)
                    Image.network(
                      snapshot.data!['imageUrl'],
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  SizedBox(height: 16),
                  Text(
                    snapshot.data!['content'],
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 16),
                  // 좋아요 버튼 추가
                  Row(
                    children: [
                      Text(
                        '좋아요 수: $likeCount',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(width: 8),
                      if (!liked)
                        ElevatedButton(
                          onPressed: _likePost,
                          child: Text('좋아요'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          } else {
            return Center(child: Text('게시글을 찾을 수 없습니다.'));
          }
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchPostDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedBoard = prefs.getString('selectedBoard');
    if (selectedBoard == null) {
      throw Exception('게시판을 선택하지 않았습니다.');
    }
    try {
      DatabaseEvent event = await postRef.once();
      DataSnapshot snapshot = event.snapshot;
      Map<dynamic, dynamic>? postData =
      snapshot.value as Map<dynamic, dynamic>?;

      if (postData != null) {
        return {
          'title': postData['title'],
          'content': postData['content'],
          'timestamp': postData['timestamp'],
          'imageUrl': postData['imageUrl'], // 이미지 URL 추가
        };
      } else {
        throw Exception('게시글 데이터가 없습니다.');
      }
    } catch (error) {
      print("게시글 상세 정보를 가져오는 데 실패했습니다: $error");
      throw error;
    }
  }
}