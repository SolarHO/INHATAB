
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostDetailPage extends StatelessWidget {
  final String postId;

  const PostDetailPage({Key? key, required this.postId}) : super(key: key);

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
      DatabaseReference postRef = FirebaseDatabase.instance
          .reference()
          .child('boardinfo')
          .child('boardstat')
          .child(selectedBoard)
          .child(postId)
          .child('contents');

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