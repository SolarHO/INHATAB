import 'package:flutterflow_ui/flutterflow_ui.dart';
import '../widget/chat_widget.dart' show ChatWidget;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ChatModel extends FlutterFlowModel<ChatWidget> with ChangeNotifier {
  final unfocusNode = FocusNode();

  List<Map<String, dynamic>> _chatRooms = [];
  Map<String, String> _latestMessageTimes = {};

  List<Map<String, dynamic>> get chatRooms => _chatRooms;
  Map<String, String> get latestMessageTimes => _latestMessageTimes;
  @override
  void initState(BuildContext context) {
    fetchChatRooms();
    // ChangeNotifier의 addListener를 통해 상태 변경 감지
    addListener(() {});
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    super.dispose();
  }

  Future<void> fetchChatRooms() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null) {
      throw Exception('사용자 ID를 찾을 수 없습니다.');
    }

    DatabaseReference userChatRef = FirebaseDatabase.instance.reference().child('userChats').child(userId);
    DatabaseEvent event = await userChatRef.once();
    DataSnapshot snapshot = event.snapshot;

    List<Map<String, dynamic>> userChatRooms = [];
    if (snapshot.value != null) {
      Map<dynamic, dynamic> chatRoomsData = snapshot.value as Map<dynamic, dynamic>;
      for (var value in chatRoomsData.values) {
        String chatId = value['chatId'];
        String opponentId = await _getOpponentId(chatId, userId);

        String opponentName = await _fetchUserName(opponentId);

        userChatRooms.add({
          'chatId': chatId,
          'timestamp': value['timestamp'],
          'userName': opponentName,
        });

        // 채팅방의 최근 메시지 시간 업데이트
        updateLatestMessageTime(chatId);
      }
    }

    _chatRooms = userChatRooms;
    notifyListeners();
  }

  Future<String> _getOpponentId(String chatId, String userId) async {
    try {
      DatabaseReference chatRef = FirebaseDatabase.instance.reference().child('chat').child(chatId);
      DataSnapshot snapshot = await chatRef.once().then((event) => event.snapshot);
      print("Snapshot value: ${snapshot.value}");
      if (snapshot.value != null) {
        Map<dynamic, dynamic> chatData = snapshot.value as Map<dynamic, dynamic>;
        print("Chat data: $chatData");

        // 'users'가 List 형태인지 Map 형태인지 확인
        if (chatData['users'] is List) {
          List<dynamic> users = chatData['users'] as List<dynamic>;
          print("Users (List): $users");
          return users.firstWhere((user) => user != userId, orElse: () => '알 수 없음');
        } else if (chatData['users'] is Map) {
          Map<dynamic, dynamic> usersMap = chatData['users'] as Map<dynamic, dynamic>;
          List<String> userIds = [];
          usersMap.forEach((key, value) {
            if (key != userId && value is String) {
              userIds.add(value);
            } else if (value is Map && value['status'] != 'deleted') {
              userIds.add(key);
            }
          });
          print("Users (Map): $userIds");
          return userIds.isNotEmpty ? userIds[0] : '알 수 없음';
        }
      }
    } catch (error) {
      print("Error fetching opponent ID: $error");
    }
    return '알 수 없음'; // 상대방 ID를 찾을 수 없을 때 반환할 기본값
  }

  //채팅방의 최신 메시지 시간을 업데이트하는 메서드
  Future<void> updateLatestMessageTime(String chatId) async {
    DatabaseReference messagesRef = FirebaseDatabase.instance.reference().child('chat').child(chatId).child('messages');
    messagesRef.limitToLast(1).onChildAdded.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final timestamp = data['timestamp'] as String;
        _latestMessageTimes[chatId] = timestamp;
        notifyListeners();
      }
    });
  }



  //사용자와 채팅을 시작하는 메서드
  Future<void> startChatWithUser(String postUserId, BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null) {
      throw Exception('사용자 ID를 찾을 수 없습니다.');
    }

    DatabaseReference chatRef = FirebaseDatabase.instance.reference().child('chat');
    DatabaseEvent event = await chatRef.once();
    DataSnapshot snapshot = event.snapshot;
    bool chatRoomExists = false;
    String? existingChatId;

    if (snapshot.value != null) {
      Map<dynamic, dynamic> chatRooms = snapshot.value as Map<dynamic, dynamic>;
      chatRooms.forEach((key, value) {
        List<dynamic> users = value['users'];
        if (users.contains(userId) && users.contains(postUserId)) {
          chatRoomExists = true;
          existingChatId = key;
        }
      });
    }

    if (chatRoomExists) {

      _showChatRoomExistsDialog(context);
    } else {
      DatabaseReference newChatRef = chatRef.push();
      String formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

      await newChatRef.set({
        'users': [userId, postUserId],
        'timestamp': formattedTimestamp,
      });

      DatabaseReference userChatRef = FirebaseDatabase.instance.reference().child('userChats');
      await userChatRef.child(userId).child(newChatRef.key!).set({
        'chatId': newChatRef.key!,
        'timestamp': formattedTimestamp,
        'userName': await _fetchUserName(postUserId),
      });
      await userChatRef.child(postUserId).child(newChatRef.key!).set({
        'chatId': newChatRef.key!,
        'timestamp': formattedTimestamp,
        'userName': await _fetchUserName(userId),
      });

      fetchChatRooms(); // 채팅방 목록 업데이트
      _showChatRoomCreatedDialog(context); // 채팅방 생성 다이얼로그 표시
    }
  }

  Future<String> _fetchUserName(String userId) async {
    DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(userId);
    DatabaseEvent event = await userRef.once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.value == null) {
      return '알 수 없음';
    }

    Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;
    return userData['name'] ?? '익명';
  }

  void _showChatRoomExistsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('채팅방 존재'),
          content: Text('이미 동일한 구성원의 채팅방이 존재합니다.'),
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

  void _showChatRoomCreatedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('채팅방 생성됨'),
          content: Text('채팅방이 성공적으로 생성되었습니다.'),
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

  Future<void> updateUserName(String newName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null) {
      throw Exception('사용자 ID를 찾을 수 없습니다.');
    }

    DatabaseReference userChatRef = FirebaseDatabase.instance.reference().child('userChats').child(userId);
    DataSnapshot snapshot = await userChatRef.once().then((event) => event.snapshot);

    if (snapshot.value != null) {
      Map<dynamic, dynamic> chatRooms = snapshot.value as Map<dynamic, dynamic>;

      for (var key in chatRooms.keys) {
        DatabaseReference chatRoomRef = FirebaseDatabase.instance.reference().child('chat').child(chatRooms[key]['chatId']);
        DataSnapshot chatRoomSnapshot = await chatRoomRef.once().then((event) => event.snapshot);

        if (chatRoomSnapshot.value != null) {
          DatabaseReference chatRoomUserRef = chatRoomRef.child('users').child(userId);
          chatRoomUserRef.update({'name': newName});
        }
      }
    }

    // 채팅방 목록 업데이트
    await fetchChatRooms();
  }

  Future<String?> getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  void refreshChatRooms() {
    fetchChatRooms();
  }
}
