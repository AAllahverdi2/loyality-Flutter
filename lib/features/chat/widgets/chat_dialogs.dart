import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';

class ChatDialogs {
  ChatDialogs._();

  /// Söhbəti sonlandırmaq üçün təsdiq dialoqu
  static Future<bool> showCloseConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('chat_close_dialog_title')),
        content: Text(
          tr('chat_close_dialog_desc'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('chat_close_dialog_no')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              tr('chat_close_dialog_yes'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// Şəkil seçimi üçün Modal Bottom Sheet (Kamera və ya Qalereya)
  static Future<ImageSource?> showAttachmentPicker(BuildContext context) async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.base.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.base),
                ),
                title: Text(
                  tr('chat_attach_camera'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(tr('chat_attach_camera_desc')),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: Colors.blue),
                ),
                title: Text(
                  tr('chat_attach_gallery'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(tr('chat_attach_gallery_desc')),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }
}

