import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';

class SupportTopic {
  final String id;
  final String? priority;
  final String? priorityName;
  final bool isActive;
  final String? createdDate;
  final String name;
  final String? description;

  const SupportTopic({
    required this.id,
    this.priority,
    this.priorityName,
    this.isActive = true,
    this.createdDate,
    required this.name,
    this.description,
  });

  factory SupportTopic.fromJson(Map<String, dynamic> json) {
    return SupportTopic(
      id: json['id']?.toString() ?? '',
      priority: json['priority']?.toString(),
      priorityName: json['priorityName']?.toString(),
      isActive: json['isActive'] == true || json['isActive'] == 1,
      createdDate: json['createdDate']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'priority': priority,
      'priorityName': priorityName,
      'isActive': isActive,
      'createdDate': createdDate,
      'name': name,
      'description': description,
    };
  }

  String? get localizedPriorityName {
    final raw = (priorityName ?? priority ?? '').trim().toLowerCase();
    if (raw.isEmpty) return priorityName;
    if (raw == 'low' || raw == 'aşağı' || raw == 'asagi' || raw == '1') {
      return tr('support_priority_low');
    } else if (raw == 'normal' || raw == '2') {
      return tr('support_priority_normal');
    } else if (raw == 'medium' || raw == 'orta') {
      return tr('support_priority_medium');
    } else if (raw == 'high' ||
        raw == 'yüksək' ||
        raw == 'yuksek' ||
        raw == '3') {
      return tr('support_priority_high');
    } else if (raw == 'urgent' ||
        raw == 'critical' ||
        raw == 'kritik' ||
        raw == '4') {
      return tr('support_priority_critical');
    }
    return priorityName;
  }

  Color get priorityColor {
    final p = (priority ?? priorityName ?? '').toLowerCase();
    if (p == 'high' ||
        p == 'urgent' ||
        p == 'critical' ||
        p == 'kritik' ||
        p == 'yüksək' ||
        p == 'yuksek' ||
        p == '3' ||
        p == '4') {
      return const Color(0xFFEF4444);
    } else if (p == 'medium' || p == 'orta') {
      return const Color(0xFFF59E0B);
    } else if (p == 'low' || p == 'aşağı' || p == 'asagi' || p == '1') {
      return const Color(0xFF10B981);
    }
    return const Color(0xFF6B7280);
  }

  IconData get iconData {
    final n = name.toLowerCase();
    if (n.contains('işçi') ||
        n.contains('isci') ||
        n.contains('employee') ||
        n.contains('personal')) {
      return Icons.badge_outlined;
    } else if (n.contains('bonus') ||
        n.contains('balans') ||
        n.contains('xal') ||
        n.contains('pul')) {
      return Icons.account_balance_wallet_outlined;
    } else if (n.contains('endirim') ||
        n.contains('təklif') ||
        n.contains('kampaniya') ||
        n.contains('discount')) {
      return Icons.local_offer_outlined;
    } else if (n.contains('tərəfdaş') ||
        n.contains('terefdas') ||
        n.contains('partner') ||
        n.contains('mağaza')) {
      return Icons.storefront_outlined;
    } else if (n.contains('kart') ||
        n.contains('barkod') ||
        n.contains('card') ||
        n.contains('barcode')) {
      return Icons.qr_code_scanner_rounded;
    } else if (n.contains('təhlükəsizlik') ||
        n.contains('şifrə') ||
        n.contains('hesab') ||
        n.contains('login')) {
      return Icons.security_outlined;
    } else if (n.contains('şikayət') ||
        n.contains('irad') ||
        n.contains('problem') ||
        n.contains('xəta')) {
      return Icons.report_problem_outlined;
    }
    return Icons.chat_bubble_outline_rounded;
  }
}
