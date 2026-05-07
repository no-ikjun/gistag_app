import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.markOnly = false, this.width, this.height});

  final bool markOnly;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      markOnly
          ? 'assets/images/logo_mark.svg'
          : 'assets/images/logo_gistag.svg',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
