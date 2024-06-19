import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:INHATAB/model/chat_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:restart_app/restart_app.dart';
class ProfileModel extends ChangeNotifier {
  /// State fields for stateful widgets in this page.
  final unfocusNode = FocusNode();

  String userName = '';
  String email = '';
  String profileImageUrl = '';

  void initState(BuildContext context) {
    fetchUserProfile();
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    super.dispose();
  }

  Future<void> fetchUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null) {
      throw Exception('사용자 ID를 찾을 수 없습니다.');
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    DatabaseReference userRef = FirebaseDatabase.instance.reference().child(
        'users').child(userId);
    DataSnapshot snapshot = await userRef.once().then((event) =>
    event.snapshot);

    if (snapshot.value != null) {
      Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;
      userName = userData['name'] ?? '익명';
      email = user.email ?? '이메일 없음';
      profileImageUrl = userData['profileImageUrl'] ?? '';
      notifyListeners();
    }
  }

  Future<void> updateUserProfile(String newName, String newPassword,
      BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    // 비밀번호 업데이트
    if (newPassword.isNotEmpty) {
      await user.updatePassword(newPassword);
    }

    // 이름 업데이트
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null) {
      throw Exception('사용자 ID를 찾을 수 없습니다.');
    }

    DatabaseReference userRef = FirebaseDatabase.instance.reference().child(
        'users').child(userId);
    await userRef.update({'name': newName});
    userName = newName;
    notifyListeners();

    // ChatModel의 refreshChatRooms 호출
    Provider.of<ChatModel>(context, listen: false).refreshChatRooms();

    // 게시글 작성자 이름 업데이트
    await _updatePostWriterName(userId, newName);
  }

  Future<void> _updatePostWriterName(String userId, String newName) async {
    DatabaseReference postsRef = FirebaseDatabase.instance.reference().child(
        'boardinfo').child('boardstat');
    DataSnapshot postsSnapshot = await postsRef.once().then((event) =>
    event.snapshot);

    if (postsSnapshot.value != null) {
      Map<dynamic, dynamic> boards = postsSnapshot.value as Map<dynamic,
          dynamic>;

      for (var board in boards.values) {
        if (board is Map) {
          for (var post in board.values) {
            if (post is Map && post['uid'] == userId) {
              String postId = post['postId'];
              DatabaseReference postRef = postsRef.child(postId);
              await postRef.update({'name': newName});

              // 댓글과 대댓글의 작성자명 업데이트
              DatabaseReference commentsRef = postRef.child('contents').child(
                  'comment');
              DataSnapshot commentsSnapshot = await commentsRef.once().then((
                  event) => event.snapshot);
              if (commentsSnapshot.value != null) {
                Map<dynamic, dynamic> comments = commentsSnapshot.value as Map<
                    dynamic,
                    dynamic>;
                for (var comment in comments.entries) {
                  if (comment.value['userId'] == userId) {
                    await commentsRef.child(comment.key).update(
                        {'userName': newName});
                  }
                  if (comment.value['replies'] != null) {
                    Map<dynamic, dynamic> replies = comment
                        .value['replies'] as Map<dynamic, dynamic>;
                    for (var reply in replies.entries) {
                      if (reply.value['userId'] == userId) {
                        await commentsRef.child(comment.key)
                            .child('replies')
                            .child(reply.key)
                            .update({'userName': newName});
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  Future<bool> verifyCurrentPassword(String password) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    final authCredential = EmailAuthProvider.credential(
        email: user.email!, password: password);
    try {
      await user.reauthenticateWithCredential(authCredential);
      return true;
    } catch (e) {
      return false;
    }
  }


  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');

    // 로그아웃 후 로그인 페이지로 이동
    context.go('/');
  }

  Future<void> _markCommentsAsDeleted(String userId) async {
    DatabaseReference postsRef = FirebaseDatabase.instance.reference().child(
        'boardinfo').child('boardstat');
    DataSnapshot postsSnapshot = await postsRef.once().then((event) =>
    event.snapshot);

    if (postsSnapshot.value != null) {
      Map<dynamic, dynamic> boards = postsSnapshot.value as Map<dynamic,
          dynamic>;

      for (var boardKey in boards.keys) {
        var board = boards[boardKey];
        if (board is Map) {
          for (var postKey in board.keys) {
            var post = board[postKey];
            if (post is Map && post['uid'] == userId) {
              String postId = postKey;
              print('Processing postId: $postId');
              DatabaseReference commentsRef = postsRef.child(boardKey).child(
                  postId).child('contents').child('comment');
              DataSnapshot commentsSnapshot = await commentsRef.once().then((
                  event) => event.snapshot);

              if (commentsSnapshot.value != null) {
                Map<dynamic, dynamic> comments = commentsSnapshot.value as Map<
                    dynamic,
                    dynamic>;
                for (var comment in comments.entries) {
                  if (comment.value['userId'] == userId) {
                    await commentsRef.child(comment.key).update({
                      'anony': false,
                      'userName': '탈퇴된 사용자',
                      'userId': 'unknown'
                    });
                    print('댓글 업데이트: ${comment.key}');
                  }
                  if (comment.value['replies'] != null) {
                    Map<dynamic, dynamic> replies = comment
                        .value['replies'] as Map<dynamic, dynamic>;
                    for (var reply in replies.entries) {
                      if (reply.value['userId'] == userId) {
                        await commentsRef.child(comment.key)
                            .child('replies')
                            .child(reply.key)
                            .update({
                          'userName': '탈퇴된 사용자',
                          'userId': 'unknown'
                        });
                        print('대댓글 업데이트: ${reply.key}');
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('로그인된 사용자가 없습니다.');
      throw Exception('로그인된 사용자가 없습니다.');
    }

    String? userId = user.uid;


      // 댓글 업데이트
      print('댓글 업데이트 시작');
      await _markCommentsAsDeleted(userId);
      print('댓글 업데이트 완료');

      // 채팅방 업데이트
      print('채팅방 업데이트 시작');
      DatabaseReference userChatRef = FirebaseDatabase.instance.reference().child('userChats').child(userId);
      DataSnapshot snapshot = await userChatRef.once().then((event) => event.snapshot);

      if (snapshot.value != null) {
        Map<dynamic, dynamic> chatRooms = snapshot.value as Map<dynamic, dynamic>;
        for (var key in chatRooms.keys) {
          DatabaseReference chatRoomRef = FirebaseDatabase.instance.reference().child('chat').child(chatRooms[key]['chatId']);
          DataSnapshot chatRoomSnapshot = await chatRoomRef.once().then((event) => event.snapshot);
        }
      }
      print('채팅방 업데이트 완료');

      // 사용자 데이터베이스에서 삭제
      print('사용자 데이터베이스에서 삭제 시작');
      DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(userId);
      await userRef.remove();
      print('사용자 데이터베이스에서 삭제 완료');

      // Firebase Auth에서 사용자 삭제
      print('Firebase Auth에서 사용자 삭제 시작');
      await user.delete();
      print('Firebase Auth에서 사용자 삭제 완료');

      // 로그아웃 처리 및 SharedPreferences 정리
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        print("Error signing out from Firebase Auth: $e");
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');

      // 앱 재시작
    // 로그아웃 처리
    await logout(context);
    // 앱 종료 처리
    SystemNavigator.pop();
  }
}