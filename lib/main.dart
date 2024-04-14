import 'package:flutter/material.dart';
import 'package:sample/create_account_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:sample/login_widget.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final GoRouter _router = GoRouter(
    initialLocation: "/", //앱 시작시 초기 경로 path
    routes: [
      GoRoute(
        path: "/", //시작 페이지(추후에 homepage로 수정)
        name: "login",
        builder: (context, state) => LoginWidget(),
      ),
      GoRoute(
        path: "/CreateAccount",
        name: "CreateAccount",
        builder: (context, state) => CreateAccountWidget(),
      ),
    ]
  );
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      routerDelegate: _router.routerDelegate, //routeInformationParser에서 변환된 값을 어떤 라우트로 보여줄 지 정하는 함수
      routeInformationParser: _router.routeInformationParser, //라우트 상태 반환 함수
    );
  }
}

