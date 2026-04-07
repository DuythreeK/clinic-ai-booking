import 'package:flutter/material.dart';

import '../../theme/admin_app_theme.dart';

class AdminBottomNavigationBar extends StatelessWidget {
  const AdminBottomNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<AdminBottomNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AdminAppTheme.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AdminAppTheme.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2F4159).withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onChanged(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            items[i].icon,
                            size: 20,
                            color: i == selectedIndex
                                ? AdminAppTheme.primary
                                : AdminAppTheme.textSecondary,
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 24,
                            child: Center(
                              child: Text(
                                items[i].label,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: i == selectedIndex
                                          ? AdminAppTheme.primary
                                          : AdminAppTheme.textSecondary,
                                      fontSize: 10,
                                      height: 1.1,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminBottomNavigationItem {
  const AdminBottomNavigationItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
