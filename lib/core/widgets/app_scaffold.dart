import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  int _indexFromLocation(String location) {
    if (location.startsWith('/notes')) return 0;
    if (location.startsWith('/folders')) return 1;
    if (location.startsWith('/search')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
    }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/notes');
        break;
      case 1:
        context.go('/folders');
        break;
      case 2:
        context.go('/search');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.note_alt_outlined), label: 'Notes'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), label: 'Folders'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
