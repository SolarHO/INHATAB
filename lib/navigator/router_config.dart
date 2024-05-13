import 'package:INHATAB/navigator/BottomNavigation.dart';
import 'package:INHATAB/widget/alert_widget.dart';
import 'package:INHATAB/widget/bbs_widget.dart';
import 'package:INHATAB/widget/chat_widget.dart';
import 'package:INHATAB/widget/create_account_widget.dart';
import 'package:INHATAB/widget/home_page_widget.dart';
import 'package:INHATAB/widget/login_widget.dart';
import 'package:INHATAB/widget/schedule_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:INHATAB/widget/boardload_widget.dart';
import 'package:INHATAB/writeboard.dart';

import 'package:INHATAB/PostDetail.dart';
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(initialLocation: '/login', redirect: (context, state) {
    // FirebaseAuth 인스턴스를 가져옴(로그인정보)
    final user = FirebaseAuth.instance.currentUser;

    // 사용자가 로그인되어 있지 않고 현재 경로가 로그인 페이지가 아닌 경우
    if (user == null && state.location != '/login') {
      // 로그인 페이지로 리디렉션
      return '/login';
    }

    // 그렇지 않으면 현재 경로를 그대로 사용
    return null;
  }, routes: [
  ShellRoute( //네비게이션 바 셸 라우터
    navigatorKey: _shellNavigatorKey,
    builder: (context, state, child) =>
        BottomNavigationBarScaffold(child: child),
    routes: [
      GoRoute(
        path: '/', //홈 페이지 라우터
        pageBuilder: (context, state) => const NoTransitionPage(child: HomePageWidget()),
      ),
      GoRoute(
        path: '/Schedule', //시간표 페이지 라우터
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ScheduleWidget(),
        ),
      ),
      GoRoute(
        path: '/Chat', //채팅 페이지 라우터
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ChatWidget(),
        ),
      ),
      GoRoute(
        path: '/Bbs', //게시판 페이지 라우터
        pageBuilder: (context, state) => const NoTransitionPage(
          child: BbsWidget(),
        ),
      ),
      GoRoute(
        path: '/Alert', //알림 페이지 라우터
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AlertWidget(),
        ),
      ),
    ],  
  ),
  GoRoute(
    path: '/login', //로그인 페이지 라우터
    name: 'login',
    builder: (context, state) => const LoginWidget(),
  ),
  GoRoute(
    path: '/CreateAccount', //회원가입 페이지 라우터
    name: 'CreateAccount',
    builder: (context, state) => const CreateAccountWidget(),
  ),
  GoRoute(
    path: '/Boardload', //글목록 페이지 라우터
    name: 'Boardload',
    builder: (context, state) => const BoardloadWidget(),
  ),
  GoRoute(
    path: '/WriteBoardPage', //글쓰기 페이지 라우터
    name: 'WriteBoard',
    builder: (context, state) => const WriteBoardPage(),
  ),

  GoRoute(
    path: "/PostDetailPage:postId",
    name: "PostDetailPage",
    builder: (context, state) {
      final postId = state.pathParameters['postId']; // 경로에서 postId를 가져옵니다.
      return PostDetailPage(postId: postId ?? ''); // postId가 null일 경우 빈 문자열로 처리합니다.
    },
  ),

  //라우터 추가시 이 아래에 추가
]);