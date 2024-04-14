import 'package:flutter/material.dart';
import 'package:flutter_tcinhide/create_account_widget.dart';
import 'package:flutter_tcinhide/testpage.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tcinhide/login_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,);


  runApp(MyApp());

}


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
      GoRoute(
        path: "/TestPage",
        name: "TestPage",
        builder: (context, state) => TestPage(),
      ),
    ]
  );
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      routeInformationProvider: _router.routeInformationProvider,
      routerDelegate: _router.routerDelegate, //routeInformationParser에서 변환된 값을 어떤 라우트로 보여줄 지 정하는 함수
      routeInformationParser: _router.routeInformationParser, //라우트 상태 반환 함수

    );

  }

}

