import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../utils/tv_key_helper.dart';

class NavItemData {
  final IconData icon;
  final String label;
  const NavItemData(this.icon, this.label);
}

class Sidebar extends StatelessWidget {
  final List<NavItemData> navItems;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onEnterContent;

  const Sidebar({
    super.key,
    required this.navItems,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onEnterContent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 112,
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        border: Border(right: BorderSide(color: colors.outline)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(Icons.tv, color: colors.onSurface, size: 32),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: navItems.length,
              itemBuilder: (context, i) => _SidebarItem(
                data: navItems[i],
                isSelected: selectedIndex == i,
                autofocus: i == selectedIndex,
                onTap: () => onItemSelected(i),
                onEnterContent: onEnterContent,
              ),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(color: colors.outline),
            ),
            child: Icon(
              Icons.person_outline,
              color: colors.onSurfaceVariant,
              size: 24,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final NavItemData data;
  final bool isSelected;
  final bool autofocus;
  final VoidCallback onTap;
  final VoidCallback onEnterContent;

  const _SidebarItem({
    required this.data,
    required this.isSelected,
    this.autofocus = false,
    required this.onTap,
    required this.onEnterContent,
  });

  void _select() {
    onTap();
    onEnterContent();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Focus(
        autofocus: autofocus,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _select();
            return KeyEventResult.handled;
          }
          if (isTvActivateEvent(event)) {
            _select();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Builder(
          builder: (ctx) {
            final focused = Focus.of(ctx).hasFocus;
            final emphasised = focused || isSelected;
            return GestureDetector(
              onTap: _select,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                foregroundDecoration: focusRing(colors, focused),
                decoration: BoxDecoration(
                  color: emphasised
                      ? colors.surfaceContainerHigh
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 3,
                          height: 28,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    Column(
                      children: [
                        Icon(
                          data.icon,
                          color: emphasised
                              ? colors.onSurface
                              : colors.onSurfaceVariant,
                          size: 26,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelMedium?.copyWith(
                            color: emphasised
                                ? colors.onSurface
                                : colors.onSurfaceVariant,
                            fontWeight: emphasised
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
