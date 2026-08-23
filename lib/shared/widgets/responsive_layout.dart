import 'package:flutter/material.dart';
import 'package:presenza/config/theme/app_colors.dart';

/// Navigation item definition for responsive shells.
class ShellNavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const ShellNavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// A responsive shell widget that automatically displays:
/// - Bottom Navigation Bar on Mobile (< 768px)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    Icon(
                      Icons.school_rounded,
                      color: isDark ? AppColors.primaryDark : AppColors.primary,
                      size: 28,
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

    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onIndexChanged,
          type: BottomNavigationBarType.fixed,
          items: items.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.activeIcon),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}
