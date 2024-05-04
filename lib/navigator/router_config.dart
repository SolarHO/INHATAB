import 'package:INHATAB/navigator/BottomNavigation.dart';
import 'package:INHATAB/widget/alert_widget.dart';
import 'package:INHATAB/widget/bbs_widget.dart';
import 'package:INHATAB/widget/chat_widget.dart';
import 'package:INHATAB/widget/create_account_widget.dart';
import 'package:INHATAB/widget/home_page_widget.dart';
import 'package:INHATAB/widget/login_widget.dart';
import 'package:INHATAB/widget/schedule_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(initialLocation: '/login', routes: [
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
  //라우터 추가시 이 아래에 추가
]);