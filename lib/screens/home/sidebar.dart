import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/tv_key_helper.dart';

class NavItemData {
  final IconData icon;
  final String label;
  const NavItemData(this.icon, this.label);
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────

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
    return Container(
      width: 102,
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E1A),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.07),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 36),
          _buildLogo(),
          const SizedBox(height: 24),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: Colors.white.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 8),
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
          _buildProfile(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return const Column(
      children: [
        Icon(Icons.tv, color: Color(0xFF6C63FF), size: 34),
        SizedBox(height: 4),
        Text(
          'SMART\nTV',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF6C63FF),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildProfile() {
    return Column(
      children: [
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          color: Colors.white.withValues(alpha: 0.06),
        ),
        const SizedBox(height: 16),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 22),
        ),
      ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      child: Focus(
        autofocus: autofocus,
        onKeyEvent: (node, event) {
          // ArrowRight → move into content
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
            return GestureDetector(
              onTap: _select,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: focused
                      ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                      : isSelected
                      ? const Color(0xFF6C63FF).withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: focused
                        ? const Color(0xFF6C63FF)
                        : isSelected
                        ? const Color(0xFF6C63FF).withValues(alpha: 0.5)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      data.icon,
                      color: focused || isSelected
                          ? const Color(0xFF6C63FF)
                          : Colors.white.withValues(alpha: 0.4),
                      size: 24,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: focused || isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        fontSize: 9.5,
                        fontWeight: focused || isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
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
