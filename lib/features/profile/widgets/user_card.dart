import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';

class UserCard extends StatelessWidget {
  const UserCard({
    this.name = 'İstifadəçi',
    this.role = '',
    this.status = 'Standart Üzv',
    this.avatarUrl,
    this.onEditTap,
    super.key,
  });

  final String name;
  final String role;
  final String status;
  final String? avatarUrl;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
        // Avatar with edit badge
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cardBg, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? Image.network(
                          avatarUrl!,
                          headers: ApiClient.instance.authHeaders,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: isDark
                                ? const Color(0xFF27272A)
                                : const Color(0xFFE5E7EB),
                            child: Icon(
                              Icons.person_rounded,
                              size: 54,
                              color: isDark
                                  ? const Color(0xFF71717A)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        )       
                      : Container(
                          color: isDark
                              ? const Color(0xFF27272A)
                              : const Color(0xFFE5E7EB),
                          child: Icon(
                            Icons.person_rounded,
                            size: 54,
                            color: isDark
                                ? const Color(0xFF71717A)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onEditTap,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: textColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBg, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // User info
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          role,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: 12),

        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    ),
  );
}
}
