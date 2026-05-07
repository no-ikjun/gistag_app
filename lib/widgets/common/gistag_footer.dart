import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/app_theme.dart';
import 'gistag_pressable.dart';

class GistagFooter extends StatelessWidget {
  const GistagFooter({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _selectedColor = GistagColors.primary;
  static const _unselectedColor = GistagColors.primarySoft;
  static const _borderColor = GistagColors.border;

  // 기존 Figma 값(84/32)이 앱에서는 크게 느껴져서,
  // 기본값을 더 컴팩트하게 잡되 필요하면 쉽게 조정 가능하도록 상수화.
  static const double _barHeight = 60;
  static const double _iconSize = 28;
  static const double _labelGap = 3;
  static const double _itemGap = 80;
  static const EdgeInsets _contentPadding = EdgeInsets.only(
    left: 20,
    right: 20,
    top: 6,
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _borderColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _barHeight,
          child: Padding(
            padding: _contentPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FooterItem(
                  label: '랭킹',
                  selected: selectedIndex == 1,
                  selectedAsset: 'assets/images/footer/ranking_selected.svg',
                  unselectedAsset:
                      'assets/images/footer/ranking_unselected.svg',
                  onTap: () => onSelected(1),
                  iconSize: _iconSize,
                  labelGap: _labelGap,
                ),
                const SizedBox(width: _itemGap),
                _FooterItem(
                  label: '홈',
                  selected: selectedIndex == 0,
                  selectedAsset: 'assets/images/footer/home_selected.svg',
                  unselectedAsset: 'assets/images/footer/home_unselected.svg',
                  onTap: () => onSelected(0),
                  iconSize: _iconSize,
                  labelGap: _labelGap,
                ),
                const SizedBox(width: _itemGap),
                _FooterItem(
                  label: '기록',
                  selected: selectedIndex == 2,
                  selectedAsset: 'assets/images/footer/history_selected.svg',
                  unselectedAsset:
                      'assets/images/footer/history_unselected.svg',
                  onTap: () => onSelected(2),
                  iconSize: _iconSize,
                  labelGap: _labelGap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterItem extends StatelessWidget {
  const _FooterItem({
    required this.label,
    required this.selected,
    required this.selectedAsset,
    required this.unselectedAsset,
    required this.onTap,
    required this.iconSize,
    required this.labelGap,
  });

  final String label;
  final bool selected;
  final String selectedAsset;
  final String unselectedAsset;
  final VoidCallback onTap;
  final double iconSize;
  final double labelGap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected
        ? GistagFooter._selectedColor
        : GistagFooter._unselectedColor;

    return SizedBox(
      width: 36,
      child: GistagPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        scaleDownTo: 0.96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: SvgPicture.asset(
                selected ? selectedAsset : unselectedAsset,
              ),
            ),
            SizedBox(height: labelGap),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
