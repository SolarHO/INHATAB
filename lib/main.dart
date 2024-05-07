import 'package:flutter/material.dart';
import 'package:INHATAB/widget/create_account_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:INHATAB/widget/login_widget.dart';
import 'package:INHATAB/testpage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:INHATAB/firebase_options.dart';
import 'package:INHATAB/board.dart';
import 'package:INHATAB/writeboard.dart';
import 'package:INHATAB/PostDetail.dart';
import 'package:INHATAB/navigator/router_config.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,); // 해당 옵션을 넣어줘야 firebase관련 기능이 작동


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
      GoRoute(
        path: "/BoardPage",
        name: "BoardPage",
        builder: (context, state) => BoardPage(),
      ),
      GoRoute(
        path: "/WriteBoardPage",
        name: "WriteBoardPage",
        builder: (context, state) => WriteBoardPage(),
      ),
      GoRoute(
        path: "/PostDetailPage:postId",
        name: "PostDetailPage",
        builder: (context, state) {
          final postId = state.pathParameters['postId']; // 경로에서 postId를 가져옵니다.
          return PostDetailPage(postId: postId ?? ''); // postId가 null일 경우 빈 문자열로 처리합니다.
        },
      ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
     //title: 'Flutter Demo',

     // routeInformationProvider: _router.routeInformationProvider,
     // routerDelegate: _router.routerDelegate, //routeInformationParser에서 변환된 값을 어떤 라우트로 보여줄 지 정하는 함수
     // routeInformationParser: _router.routeInformationParser, //라우트 상태 반환 함수 ㅁ
      debugShowCheckedModeBanner: false, //우측 상단 디버그 배너 삭제
      routerConfig: router, //라우터 사용
    );
  }
}

