import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldShell extends StatelessWidget {
  const ScaffoldShell({
    super.key,
    required this.navigationShell,
    required this.tabs,
  });

  final StatefulNavigationShell navigationShell;
  final List<ShellTab> tabs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.selectedIcon ?? t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class ShellTab {
  const ShellTab({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}
