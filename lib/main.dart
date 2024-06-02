import 'package:INHATAB/model/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:INHATAB/firebase_options.dart';
import 'package:INHATAB/navigator/router_config.dart';
import 'package:provider/provider.dart'; 
import 'model/BoardModel.dart';
import 'model/PostModel.dart';
import 'model/commentModel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,); // firebase opsion
  runApp(
    MultiProvider( //Provider
      providers: [
        ChangeNotifierProvider(create: (context) => BoardModel()),
        ChangeNotifierProvider(create: (context) => PostModel()),
        ChangeNotifierProvider(create: (context) => CommentModel()),
	      ChangeNotifierProvider(create: (_) => ChatModel()),
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
      routerConfig: router, //라우터
    );
  }
}
