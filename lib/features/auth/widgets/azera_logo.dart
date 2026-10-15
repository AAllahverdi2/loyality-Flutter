import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AzeraLogo extends StatelessWidget {
  const AzeraLogo({this.width = 200, this.height = 300, super.key});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/azera.svg',
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticsLabel: 'Azera loqosu',
    );
  }
}


