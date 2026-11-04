import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../widgets/ui.dart';

const _tabs = [
  (icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Nyumbani'),
  (icon: Icons.celebration_outlined, selectedIcon: Icons.celebration, label: 'Matukio'),
  (icon: Icons.account_balance_wallet_outlined, selectedIcon: Icons.account_balance_wallet, label: 'Salio'),
  (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Akaunti'),
];

/// Tabo nne: Nyumbani, Matukio, Salio, Akaunti.
/// Simu: menyu ya chini ya glass. Kompyuta (web): menyu ya pembeni na maudhui katikati.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  void _select(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    if (isWideLayout(context)) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                child: _SideNav(current: shell.currentIndex, onSelect: _select),
              ),
              Expanded(child: MaxWidth(maxWidth: 1040, child: shell)),
            ],
          ),
        ),
      );
    }
    return MaxWidth(
      maxWidth: 720,
      child: Scaffold(
        extendBody: true,
        body: shell,
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Glass(
            color: const Color(0x99FFFFFF),
            child: NavigationBar(
              height: 64,
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _select,
              destinations: [
                for (final t in _tabs)
                  NavigationDestination(icon: Icon(t.icon), selectedIcon: Icon(t.selectedIcon), label: t.label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Menyu ya pembeni ya glass kwa skrini pana.
class _SideNav extends StatelessWidget {
  const _SideNav({required this.current, required this.onSelect});

  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 236,
      child: Glass(
        color: const Color(0x99FFFFFF),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 22, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Align(alignment: Alignment.centerLeft, child: BrandLogo(height: 42)),
              ),
              const SizedBox(height: 30),
              for (var i = 0; i < _tabs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _SideNavItem(
                    icon: current == i ? _tabs[i].selectedIcon : _tabs[i].icon,
                    label: _tabs[i].label,
                    selected: current == i,
                    onTap: () => onSelect(i),
                  ),
                ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Mialiko inayofika,\nwageni wanaofika.',
                  style: TextStyle(
                    color: MwalikoColors.muted,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('© 2026 Tembo Cloud', style: TextStyle(color: MwalikoColors.muted, fontSize: 11.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? MwalikoColors.primary : MwalikoColors.ink;
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? Colors.white.withValues(alpha: 0.8) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
