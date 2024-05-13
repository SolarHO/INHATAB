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
  late int selectedIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      setState(() {
        selectedIndex = getIndexFromPath(GoRouter.of(context).location);
      });
    }
  }

  int getIndexFromPath(String path) {
    switch (path) {
      case '/':
        return 0;
      case '/Schedule':
        return 1;
      case '/Chat':
        return 2;
      case '/Bbs':
        return 3;
      case '/Alert':
        return 4;
      default:
        return 0;
    }
  }

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
          NavigationDestination(label: '홈', icon: Icon(Icons.home,size: 30,)),
          NavigationDestination(label: '시간표', icon: Icon(Icons.schedule,size: 30)),
          NavigationDestination(label: '채팅', icon: Icon(Icons.chat,size: 30,)),
          NavigationDestination(label: '게시판', icon: Icon(Icons.content_paste,size: 30,)),
          NavigationDestination(label: '알림', icon: Icon(Icons.notifications,size: 30)),
        ],
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }
}
