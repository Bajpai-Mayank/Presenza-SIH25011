import 'package:flutter/material.dart';
import 'package:presenza/shared/widgets/animated_bottom_navbar.dart';

/// Navigation item definition for responsive shells.
class ShellNavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final double? iconSize;

  const ShellNavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.iconSize,
  });
}

/// A responsive shell widget that automatically displays:
/// - Animated Bottom Navigation Bar on Mobile (< 768px)
/// - Navigation Rail / Sidebar on Tablet & Web Desktop (>= 768px)
class ResponsiveShell extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<ShellNavigationItem> items;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const ResponsiveShell({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.items,
    required this.body,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    if (isDesktop) {
      return Scaffold(
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onIndexChanged,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Presenza',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ],
                ),
              ),
              destinations: items.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: Text(item.label),
                );
              }).toList(),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile: Use Animated Bottom Nav Bar ────────────────────────
    return Scaffold(
      appBar: appBar,
      // Use extendBody so the animated navbar can overlap
      extendBody: true,
      body: Padding(
        // Add bottom padding so content doesn't hide behind the navbar
        padding: const EdgeInsets.only(bottom: 0),
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: currentIndex,
        onTap: onIndexChanged,
        items: items.map((item) {
          return AnimatedNavItem(
            icon: item.icon,
            activeIcon: item.activeIcon,
            label: item.label,
            iconSize: item.iconSize,
          );
        }).toList(),
      ),
    );
  }
}
