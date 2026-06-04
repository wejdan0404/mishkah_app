import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.iconAsset,
    required this.activeIconAsset,
    required this.label,
  });

  final String iconAsset;
  final String activeIconAsset;
  final String label;
}

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onChanged,
  });

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const double _height = 84;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        0,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.colors.shade50,
        boxShadow: AppShadows.md,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: _NavTab(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onChanged(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  static const double _iconSize = 24;

  @override
  Widget build(BuildContext context) {
    final Color color =
        selected ? AppPalettePurple.shade200 : context.colors.shade500;

    final String asset =
        selected ? item.activeIconAsset : item.iconAsset;

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      asset,
                      width: _iconSize,
                      height: _iconSize,
                      colorFilter: selected
                          ? null
                          : ColorFilter.mode(color, BlendMode.srcIn),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontFamily: AppFontFamily.text,
                        fontSize: AppFontSizes.xxs,
                        fontWeight: selected
                            ? AppFontWeights.semibold
                            : AppFontWeights.regular,
                        color: color,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
