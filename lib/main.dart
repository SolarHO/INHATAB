import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:INHATAB/firebase_options.dart';
import 'package:INHATAB/navigator/router_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,); // 해당 옵션을 넣어줘야 firebase관련 기능이 작동
  runApp(MyApp());
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

