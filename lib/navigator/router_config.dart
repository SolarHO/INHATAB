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

final router = GoRouter(initialLocation: '/', routes: [
  ShellRoute(
    navigatorKey: _shellNavigatorKey,
    builder: (context, state, child) =>
        BottomNavigationBarScaffold(child: child),
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => const NoTransitionPage(child: HomePageWidget()),
      ),
      GoRoute(
        path: '/Schedule', // 여기서 수정
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ScheduleWidget(),
        ),
      ),
      GoRoute(
        path: '/Chat', // 여기서 수정
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ChatWidget(),
        ),
      ),
      GoRoute(
        path: '/Bbs', // 여기서 수정
        pageBuilder: (context, state) => const NoTransitionPage(
          child: BbsWidget(),
        ),
      ),
      GoRoute(
        path: '/Alert', // 여기서 수정
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AlertWidget(),
        ),
      ),
      GoRoute(
        path: '/login', // 여기서 수정
        name: 'login',
        builder: (context, state) => const LoginWidget(),
      ),
      GoRoute(
        path: '/CreateAccount', // 여기서 수정
        name: 'CreateAccount',
        builder: (context, state) => const CreateAccountWidget(),
      ),
    ],
  ),
]);