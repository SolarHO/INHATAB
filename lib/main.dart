import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:INHATAB/firebase_options.dart';
import 'package:INHATAB/navigator/router_config.dart';
import 'package:provider/provider.dart';
import '../widget/chat_widget.dart'; // ChatWidget이 정의된 파일을 임포트합니다.
import '../model/chat_model.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,); // 해당 옵션을 넣어줘야 firebase관련 기능이 작동
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatModel()), //채팅 모델
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false, //우측 상단 디버그 배너 삭제
      routerConfig: router, //라우터 사용
    );
  }
}

