import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../common/gistag_pressable.dart';

class NfcCtaButton extends StatelessWidget {
  const NfcCtaButton({
    required this.onTap,
    super.key,
    this.size = 168,
    this.showLabel = true,
    this.hapticsEnabled = false,
  });

  final VoidCallback onTap;
  final double size;
  final bool showLabel;
  final bool hapticsEnabled;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GistagPressable(
        onTap: onTap,
        hapticsEnabled: hapticsEnabled,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: GistagColors.primary,
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sensors_rounded,
                color: Colors.white,
                size: showLabel ? 52 : 58,
              ),
              if (showLabel) ...[
                const SizedBox(height: 10),
                const Text(
                  'NFC 태그',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '운동 시작하기',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
