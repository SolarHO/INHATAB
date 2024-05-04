import 'package:flutter/material.dart';
import 'package:INHATAB/navigator/router_config.dart';

void main() {
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