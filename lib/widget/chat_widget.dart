import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/chat_model.dart';
export '../model/chat_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:INHATAB/ChatRoomPage.dart';
import 'package:go_router/go_router.dart';
class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  @override
  void initState() {
    super.initState();
    Provider.of<ChatModel>(context, listen: false).fetchChatRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: GlobalKey<ScaffoldState>(),
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: Color(0x4C181BF8),
        automaticallyImplyLeading: false,
        title: Text(
          '채팅방 목록',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
            fontFamily: 'Outfit',
            color: Colors.white,
            fontSize: 22,
            letterSpacing: 0,
          ),
        ),
        actions: [],
        centerTitle: false,
        elevation: 2,
      ),
      body: Consumer<ChatModel>(
        builder: (context, chatModel, child) {
          return ListView.builder(
            itemCount: chatModel.chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatModel.chatRooms[index];
              final latestMessageTime = chatModel.latestMessageTimes[chatRoom['chatId']] ?? '시간 정보 없음';
              return ListTile(
                title: Text('${chatRoom['userName']} 님과의 채팅방'),
                subtitle: Text('최근 메시지 시간: $latestMessageTime'),
                onTap: () {
                  // go_router를 사용하여 채팅방으로 이동
                  context.go('/chatroom/${chatRoom['chatId']}');
                },
              );
            },
          );
        },
      ),
    );
  }
}