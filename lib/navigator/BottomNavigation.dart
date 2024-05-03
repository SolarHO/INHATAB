import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavigationBarScaffold extends StatefulWidget {
  const BottomNavigationBarScaffold({Key? key, required this.child})
      : super(key: key);
  final Widget child;

  @override
  State<BottomNavigationBarScaffold> createState() =>
      _BottomNavigationBarScaffoldState();
}

class _BottomNavigationBarScaffoldState
    extends State<BottomNavigationBarScaffold> {
  int selectedIndex = 0;

  void onDestinationSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/Schedule');
        break;
      case 2:
        context.go('/Chat');
        break;
      case 3:
        context.go('/Bbs');
        break;
      case 4:
        context.go('/Alert');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: const [
          NavigationDestination(label: '홈', icon: Icon(Icons.home)),
          NavigationDestination(label: '시간표', icon: Icon(Icons.schedule)),
          NavigationDestination(label: '채팅', icon: Icon(Icons.chat)),
          NavigationDestination(label: '게시판', icon: Icon(Icons.content_paste)),
          NavigationDestination(label: '알림', icon: Icon(Icons.notifications)),
        ],
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }
}