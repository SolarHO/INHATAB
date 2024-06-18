import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:INHATAB/model/chat_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

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

    DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(userId);
    DataSnapshot snapshot = await userRef.once().then((event) => event.snapshot);

    if (snapshot.value != null) {
      Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;
      userName = userData['name'] ?? '익명';
      email = user.email ?? '이메일 없음';
      profileImageUrl = userData['profileImageUrl'] ?? '';
      notifyListeners();
    }
  }

  Future<void> updateUserProfile(String newName, String newPassword, BuildContext context) async {
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

    DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(userId);
    await userRef.update({'name': newName});
    userName = newName;
    notifyListeners();

    // ChatModel의 refreshChatRooms 호출
    Provider.of<ChatModel>(context, listen: false).refreshChatRooms();

    // 게시글 작성자 이름 업데이트
    await _updatePostWriterName(userId, newName);
  }

  Future<void> _updatePostWriterName(String userId, String newName) async {
    DatabaseReference postsRef = FirebaseDatabase.instance.reference().child('boardinfo').child('boardstat');
    DataSnapshot postsSnapshot = await postsRef.once().then((event) => event.snapshot);

    if (postsSnapshot.value != null) {
      Map<dynamic, dynamic> boards = postsSnapshot.value as Map<dynamic, dynamic>;

      for (var board in boards.values) {
        if (board is Map) {
          for (var post in board.values) {
            if (post is Map && post['uid'] == userId) {
              String postId = post['postId'];
              DatabaseReference postRef = postsRef.child(postId);
              await postRef.update({'name': newName});
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

    final authCredential = EmailAuthProvider.credential(email: user.email!, password: password);
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


  Future<void> deleteAccount(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    String? userId = user.uid;

    // 채팅방 업데이트
    DatabaseReference userChatRef = FirebaseDatabase.instance.reference().child('userChats').child(userId);
    DataSnapshot snapshot = await userChatRef.once().then((event) => event.snapshot);

    if (snapshot.value != null) {
      Map<dynamic, dynamic> chatRooms = snapshot.value as Map<dynamic, dynamic>;
      for (var key in chatRooms.keys) {
        DatabaseReference chatRoomRef = FirebaseDatabase.instance.reference().child('chat').child(chatRooms[key]['chatId']);
        DataSnapshot chatRoomSnapshot = await chatRoomRef.once().then((event) => event.snapshot);

      }
    }

    // 사용자 데이터베이스에서 삭제
    DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(userId);
    await userRef.remove();

    // Firebase Auth에서 사용자 삭제
    await user.delete();

    // 로그아웃 처리
    await logout(context);
    // 앱 종료 처리
    SystemNavigator.pop();

  }
}