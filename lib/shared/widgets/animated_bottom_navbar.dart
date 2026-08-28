import 'package:flutter/material.dart';
import 'package:presenza/config/theme/app_colors.dart';

/// An interactive animated bottom navigation bar where the selected item
/// "pops up" above the bar inside a circular highlighted container.
///
/// Inspired by modern mobile navigation patterns — the active icon rises
/// with a spring animation while inactive icons stay in their resting position.
class AnimatedBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AnimatedNavItem> items;

  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<AnimatedBottomNavBar> createState() => _AnimatedBottomNavBarState();
}

class _AnimatedBottomNavBarState extends State<AnimatedBottomNavBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _elevationAnims;
  late List<Animation<double>> _scaleAnims;
  late List<Animation<double>> _iconFadeAnims;

  static const double _barHeight = 70.0;
  static const double _iconPopUp = 28.0; // How far the selected icon rises
  static const double _circleSize = 52.0;
  static const Duration _animDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _initControllers();
    // Start with current tab animated
    _controllers[widget.currentIndex].forward();
  }

  void _initControllers() {
    _controllers = List.generate(widget.items.length, (i) {
      return AnimationController(
        vsync: this,
        duration: _animDuration,
      );
    });

    _elevationAnims = _controllers.map((c) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOutBack),
      );
    }).toList();

    _scaleAnims = _controllers.map((c) {
      return Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOutCubic),
      );
    }).toList();

    _iconFadeAnims = _controllers.map((c) {
      return Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOut),
      );
    }).toList();
  }

  @override
  void didUpdateWidget(covariant AnimatedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controllers[oldWidget.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight;
    final activeColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final inactiveColor = isDark ? AppColors.slate400 : AppColors.slate500;
    final circleBg = isDark ? AppColors.cardDark : Colors.white;

    return SizedBox(
      height: _barHeight + _iconPopUp / 2 + MediaQuery.of(context).padding.bottom,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Bar Background ────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: _barHeight + MediaQuery.of(context).padding.bottom,
              decoration: BoxDecoration(
                color: barColor,
                border: Border(
                  top: BorderSide(color: borderColor, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.black12).withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
            ),
          ),

          // ── Sliding Indicator ─────────────────────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 4,
            left: 0,
            right: 0,
            child: AnimatedAlign(
              duration: _animDuration,
              curve: Curves.easeOutCubic,
              alignment: Alignment(
                -1.0 + (2.0 * widget.currentIndex / (widget.items.length - 1)),
                0.0,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width / widget.items.length * 0.45,
                height: 3.5,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // ── Navigation Items ──────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom,
            height: _barHeight,
            child: Row(
              children: List.generate(widget.items.length, (index) {
                final item = widget.items[index];
                final isSelected = index == widget.currentIndex;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onTap(index),
                    child: AnimatedBuilder(
                      animation: _controllers[index],
                      builder: (context, child) {
                        final elevation = _elevationAnims[index].value;
                        final scale = _scaleAnims[index].value;
                        final iconOpacity = _iconFadeAnims[index].value;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ── Pop-up circle + icon ─────────────────────
                            Transform.translate(
                              offset: Offset(0, -elevation * _iconPopUp),
                              child: Transform.scale(
                                scale: scale,
                                child: AnimatedContainer(
                                  duration: _animDuration,
                                  width: _circleSize,
                                  height: _circleSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: circleBg,
                                    border: Border.all(
                                      color: isSelected
                                          ? activeColor
                                          : Colors.transparent,
                                      width: isSelected ? 2.5 : 0,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: activeColor.withValues(alpha: 0.25),
                                              blurRadius: 14,
                                              spreadRadius: 2,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Opacity(
                                    opacity: iconOpacity,
                                    child: Icon(
                                      isSelected ? item.activeIcon : item.icon,
                                      color: isSelected ? activeColor : inactiveColor,
                                      size: item.iconSize ?? 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // ── Label ──────────────────────────────────
                            Transform.translate(
                              offset: Offset(0, -elevation * (_iconPopUp * 0.45)),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: AnimatedDefaultTextStyle(
                                  duration: _animDuration,
                                  style: TextStyle(
                                    fontSize: isSelected ? 11.5 : 10.5,
                                    fontWeight:
                                        isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? activeColor : inactiveColor,
                                    letterSpacing: isSelected ? 0.1 : 0,
                                  ),
                                  child: Text(item.label),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single item in the [AnimatedBottomNavBar].
class AnimatedNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final double? iconSize;

  const AnimatedNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.iconSize,
  });
}
