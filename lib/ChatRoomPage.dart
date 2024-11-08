import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'package:provider/provider.dart';
import '../model/chat_model.dart'; // ChatModel이 정의된 파일을 임포트합니다.
import 'package:go_router/go_router.dart';
class ChatRoomPage extends StatefulWidget {
  final String chatId;

  const ChatRoomPage({Key? key, required this.chatId}) : super(key: key);

  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  String opponentName = '알 수 없음'; // 상대방 이름을 저장할 변수
  String? currentUserId;
  bool isAnonymous = false;
  String? opponentUserId;
  @override
  void initState() {
    super.initState();
    _fetchChatDetails();
    _fetchMessages();
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    currentUserId = await Provider.of<ChatModel>(context, listen: false).getCurrentUserId();
  }
  Future<void> _fetchChatDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null) {
      throw Exception('사용자 ID를 찾을 수 없습니다.');
    }

    DatabaseReference chatRef = FirebaseDatabase.instance.reference().child('chat').child(widget.chatId);
    chatRef.onValue.listen((event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<dynamic, dynamic> chatData = snapshot.value as Map<dynamic, dynamic>;
        List<dynamic> users = chatData['users'];
        isAnonymous = chatData['isAnonymous'] ?? false;

        for (String user in users) {
          if (user != userId) {
            DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(user);
            userRef.onValue.listen((userEvent) {
              DataSnapshot userSnapshot = userEvent.snapshot;
              if (userSnapshot.value != null) {
                Map<dynamic, dynamic> userData = userSnapshot.value as Map<dynamic, dynamic>;
                setState(() {
                  opponentName = isAnonymous ? '익명' : (userData['name'] ?? '익명');
                });
              }
            });
            break;
          }
        }
      }
    });
  }

  Future<void> _fetchMessages() async {
    DatabaseReference messagesRef = FirebaseDatabase.instance.reference().child('chat').child(widget.chatId).child('messages');
    messagesRef.onChildAdded.listen((event) {
      setState(() {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          messages.add(Map<String, dynamic>.from(data));
        }
      });
      _scrollToBottom();
    });
  }

  Future<void> _sendMessage(String message) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null) {
      throw Exception('사용자 ID를 찾을 수 없습니다.');
    }

    DatabaseReference chatRef = FirebaseDatabase.instance.reference().child('chat').child(widget.chatId);
    DataSnapshot snapshot = await chatRef.once().then((event) => event.snapshot);

    String userName = '익명';
    if (snapshot.value != null) {
      Map<dynamic, dynamic> chatData = snapshot.value as Map<dynamic, dynamic>;
      bool isAnonymous = chatData['isAnonymous'] ?? false;

      if (!isAnonymous) {
        DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(userId);
        DatabaseEvent event = await userRef.once();
        DataSnapshot userSnapshot = event.snapshot;

        if (userSnapshot.value != null) {
          Map<dynamic, dynamic> userData = userSnapshot.value as Map<dynamic, dynamic>;
          userName = userData['name'] ?? '익명';
        }
      }
    }

    DatabaseReference messagesRef = FirebaseDatabase.instance.reference().child('chat').child(widget.chatId).child('messages');
    String formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    await messagesRef.push().set({
      'userId': userId,
      'userName': userName,
      'message': message,
      'timestamp': formattedTimestamp,
    });

    // 최신 메시지 시간 갱신
    Provider.of<ChatModel>(context, listen: false).updateLatestMessageTime(widget.chatId);

    String toUserId = await _getOpponentUserId(userId, widget.chatId);
    String notificationMessage = isAnonymous ? '익명님이 채팅을 보냈습니다.' : '$userName님이 채팅을 보냈습니다. '; // 채팅시 알림
    await Provider.of<ChatModel>(context, listen: false).sendChatNotification(userId, toUserId, notificationMessage, message);
    _messageController.clear();
  }

  Future<String> _getOpponentUserId(String currentUserId, String chatId) async {
    DatabaseReference chatRef = FirebaseDatabase.instance.reference().child('chat').child(chatId);
    DataSnapshot snapshot = await chatRef.once().then((event) => event.snapshot);

    if (snapshot.value != null) {
      Map<dynamic, dynamic> chatData = snapshot.value as Map<dynamic, dynamic>;
      List<dynamic> users = chatData['users'];
      for (String userId in users) {
        if (userId != currentUserId) {
          return userId;
        }
      }
    }
    throw Exception('상대방 ID를 찾을 수 없습니다.');
  }
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _leaveChat() async {
    print('Attempting to leave chat...');
    print('Current user ID: $currentUserId');
    print('Opponent user ID: $opponentUserId');

    if (currentUserId == null) {
      print('Current user ID is null.');
      return;
    }

    // chat 노드에서 users 리스트에서 사용자 제거
    DatabaseReference chatUserRef = FirebaseDatabase.instance.reference().child('chat').child(widget.chatId).child('users');
    DatabaseEvent event = await chatUserRef.once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      if (snapshot.value is List) {
        List<dynamic> users = List<dynamic>.from(snapshot.value as Iterable);
        users.remove(currentUserId);
        if (users.isEmpty) {
          // 모두 나간 경우 chatId 노드 삭제
          DatabaseReference chatRef = FirebaseDatabase.instance.reference().child('chat').child(widget.chatId);
          await chatRef.remove();
        } else {
          await chatUserRef.set(users);
        }
      } else if (snapshot.value is Map) {
        Map<dynamic, dynamic> usersMap = Map<dynamic, dynamic>.from(snapshot.value as Map);
        usersMap.remove(currentUserId);
        if (usersMap.isEmpty) {
          // 모두 나간 경우 chatId 노드 삭제
          DatabaseReference chatRef = FirebaseDatabase.instance.reference().child('chat').child(widget.chatId);
          await chatRef.remove();
        } else {
          await chatUserRef.set(usersMap);
        }
      } else {
        print('Unexpected snapshot value type: ${snapshot.value.runtimeType}');
        // 현재 사용자가 유일한 사용자라면 chatId 노드 삭제
        DatabaseReference chatRef = FirebaseDatabase.instance.reference().child('chat').child(widget.chatId);
        await chatRef.remove();
      }
    } else {
      print('Snapshot value is null.');
    }

    // userChats에서 해당 채팅방 제거
    DatabaseReference userChatRef = FirebaseDatabase.instance.reference().child('userChats').child(currentUserId!).child(widget.chatId);
    await userChatRef.remove();

    // 채팅방에서 나가고 이전 화면으로 돌아감
    context.go('/Chat');
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.go('/Chat'); // 현재 페이지를 닫고 채팅 목록 페이지로 이동합니다.
        return false; // 기본 동작을 수행하지 않도록 false를 반환합니다.
      },
      child: Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: Color(0x4C181BF8),
          automaticallyImplyLeading: false,
          title: Text(
            '$opponentName님과의 채팅방',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
              fontFamily: 'Outfit',
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 0,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              context.go('/Chat');
            },
          ),

          actions: [IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _leaveChat,
          ),
          ],
          centerTitle: false,
          elevation: 2,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isOwnMessage = message['userId'] == currentUserId;
                  return Column(
                    children: [
                      Container(
                        color: isOwnMessage ? Colors.yellow : Colors.transparent,
                        child: ListTile(
                          title: Text(message['message']),
                          subtitle: Text('${message['userName']} - ${message['timestamp']}'),
                        ),
                      ),
                      Divider(height: 1, thickness: 1), 
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요...',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      if (_messageController.text.isNotEmpty) {
                        _sendMessage(_messageController.text);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}