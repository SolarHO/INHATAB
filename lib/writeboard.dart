
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
class WriteBoardPage extends StatefulWidget {
  const WriteBoardPage({Key? key}) : super(key: key);

  @override
  _WriteBoardPageState createState() => _WriteBoardPageState();
}

class _WriteBoardPageState extends State<WriteBoardPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Future<void> _savePost() async {
    try {
      // 현재 로그인된 사용자 가져오기
      User? user = FirebaseAuth.instance.currentUser;
      final String postId = generateRandomId();

      // Firebase Realtime Database에서 사용자 정보 가져오기
      DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users');
      DatabaseEvent event = await userRef.child(user!.uid).once(); // 현재 사용자의 UID에 해당하는 정보 가져오기
      DataSnapshot snapshot = event.snapshot;
      Map<dynamic, dynamic>? userData = snapshot.value as Map<dynamic, dynamic>?;

      if (userData != null) {
        String userName = userData['name'] ?? 'Unknown'; // 사용자의 이름 가져오기

        // 현재 시간 가져오기
        DateTime now = DateTime.now();

        // 시간을 원하는 형식의 문자열로 변환
        String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? selectedBoard = prefs.getString('selectedBoard');
        if (selectedBoard == null) {
          throw Exception('게시판을 선택하지 않았습니다.');
        }

        // Firebase Realtime Database에 게시글 저장
        DatabaseReference postRef = FirebaseDatabase.instance.reference().child('boardinfo').child('boardstat').child(selectedBoard).push();
        String postId = postRef.key!; // 새로운 게시글의 키 가져오기

        // 게시글 정보 저장
        await postRef.set({
          'postId': postId,
          'title': _titleController.text, // 게시글 제목
          'uid': user.uid, // 현재 사용자의 UID
          'name': userName, // 사용자의 이름
          'timestamp': timestamp, // 현재 시간을 문자열로 저장
        });

        // 게시글 내용을 별도의 하위 노드로 저장 (contents)
        DatabaseReference contentRef = postRef.child('contents');
        await contentRef.set({
          'title': _titleController.text, // 게시글 제목
          'content': _contentController.text, // 게시글 내용
          'timestamp': timestamp, // 현재 시간을 문자열로 저장
        });

        // 게시글 저장 후 이전 화면으로 이동
        GoRouter.of(context).go('/Boardload'); //경로변경
      } else {
        throw Exception('사용자 정보를 가져올 수 없습니다.');
      }
    } catch (e) {
      print('게시글 저장 오류: $e');
      GoRouter.of(context).go('/Boardload');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시글 작성'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '제목',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: '내용',
              ),
              maxLines: null, // 다중 라인 입력 가능
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _savePost,
              child: Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}

