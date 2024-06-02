import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostModel with ChangeNotifier {
  String? PostId; // 게시글 ID
  String? title; // 게시글 제목
  String? content; // 게시글 내용
  String? writerId; //작성자 Id
  String? writerName; //작성자 이름
  int? likeCount; // 좋아요 수
  String? timestamp; // 게시글 작성 시간
  Color? likebtnColor; 

  String formatTimestamp(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    // 'yyyy-MM-dd HH:mm' 형식으로 날짜와 시간을 포맷
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  // 게시글 정보를 불러오는 메서드
  Future<void> fetchPost(String postId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? selectedBoard = prefs.getString('selectedBoard');
      String? userId = prefs.getString('userId');
      DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(userId!);
      DatabaseEvent event = await userRef.child('like').child(postId!).once();
      DataSnapshot snapshot = event.snapshot;
      if(snapshot.value == null) {
        likebtnColor = Colors.grey;
      } else {
        likebtnColor = Colors.blue;
      }
      DatabaseReference postRef = FirebaseDatabase.instance.reference().child('boardinfo').child('boardstat').child(selectedBoard!).child(postId);
      snapshot = (await postRef.once()).snapshot;

      if (snapshot.value != null) {
        Map<dynamic, dynamic>? post = snapshot.value as Map<dynamic, dynamic>?;

        if (post != null) {
          PostId = postId;
          title = post['title'];
          writerId = post['uid'];
          if(post['anony'] == true) {
            writerName = "익명";
          } else {
            writerName = post['name'];
          }
          content = post['contents']['content'];
          likeCount = post['likecount'];
          timestamp = formatTimestamp(post['timestamp']);
          notifyListeners();
        }
      }
    } catch (error) {
      print("게시글 정보를 가져오는 데 실패했습니다: $error");
    }
  }

  Future<void> likePost() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? selectedBoard = prefs.getString('selectedBoard');
    if (userId == null) {
      throw Exception('사용자 ID를 찾을 수 없습니다.');
    }

    try {
      DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(userId);
      DatabaseReference postRef = FirebaseDatabase.instance.reference().child('boardinfo').child('boardstat').child(selectedBoard!).child(PostId!);
      DatabaseEvent event = await userRef.child('like').child(PostId!).once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value == null) { //아직 좋아요를 누르지 않은 글
        likeCount = (likeCount ?? 0) + 1;
        await postRef.child('likecount').set(ServerValue.increment(1));
        await userRef.child('like').child(PostId!).set(true);
        likebtnColor = Colors.blue;
      } else { //좋아요를 누른 글(좋아요 취소)
        likeCount = (likeCount ?? 0) - 1;
        await postRef.child('likecount').set(ServerValue.increment(-1));
        await userRef.child('like').child(PostId!).remove();
        likebtnColor = Colors.grey;
      }
      notifyListeners();
    } catch (error) {
      print("좋아요를 추가/취소하는 데 실패했습니다: $error");
      throw error;
    }
  }

  // 모델을 초기화하는 메서드
  void clear() {
    PostId = null;
    title = null;
    content = null;
    likeCount = null;
    timestamp = null;
    likebtnColor = null;
    notifyListeners();
  }
}