import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tənzimləmələr',
      child: Material(
        color: AppColors.settingsRing,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {},
          child: Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.settings,
            ),
            child: const Icon(Icons.settings, size: 29, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
