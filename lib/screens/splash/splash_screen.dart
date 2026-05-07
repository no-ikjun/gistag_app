import 'package:flutter/material.dart';
import 'package:scaler/scaler.dart';

import '../../app/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Center(
            child: Column(
              children: [
                Spacer(),
                Image.asset(
                  'assets/images/logo_main.png',
                  width: Scaler.width(0.6, context),
                ),
                Spacer(),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: GistagColors.primary,
                  ),
                ),
                Spacer(),
                Text(
                  '운동의 시작을 더 쉽게',
                  style: TextStyle(
                    color: GistagColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '© Gistag',
                  style: TextStyle(
                    color: GistagColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
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
