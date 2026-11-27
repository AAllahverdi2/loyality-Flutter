import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/features/history/models/transaction.dart';

enum LoyaltyTransactionKind {
  purchase,
  bonusGrant,
  bonusRedemption,
  discountApplied,
  refund,
  adjustment,
  unknown,
}

class WalletHistoryEvent {
  final String id;
  final String? walletId;
  final String? userId;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? sourceType;
  final String? sourceTypeName;
  final String? description;
  final String? transactionId;
  final DateTime? expiresAt;
  final DateTime? createdDate;

  const WalletHistoryEvent({
    required this.id,
    this.walletId,
    this.userId,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.sourceType,
    this.sourceTypeName,
    this.description,
    this.transactionId,
    this.expiresAt,
    this.createdDate,
  });

  factory WalletHistoryEvent.fromJson(Map<String, dynamic> json) {
    return WalletHistoryEvent(
      id: json['id']?.toString() ?? '',
      walletId: json['walletId']?.toString(),
      userId: json['userId']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balanceBefore: (json['balanceBefore'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0.0,
      sourceType: json['sourceType']?.toString(),
      sourceTypeName: json['sourceTypeName']?.toString(),
      description: json['description']?.toString(),
      transactionId: json['transactionId']?.toString(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'userId': userId,
      'amount': amount,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'sourceType': sourceType,
      'sourceTypeName': sourceTypeName,
      'description': description,
      'transactionId': transactionId,
      'expiresAt': expiresAt?.toIso8601String(),
      'createdDate': createdDate?.toIso8601String(),
    };
  }

  String get formattedDate {
    if (createdDate == null) return '';
    final dt = createdDate!;
    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');
    const months = [
      'Yan', 'Fev', 'Mar', 'Apr', 'May', 'İyn',
      'İyl', 'Avq', 'Sen', 'Okt', 'Noy', 'Dek'
    ];
    final monthName = months[dt.month - 1];
    return '${dt.day.toString().padLeft(2, '0')} $monthName ${dt.year}, $hourStr:$minStr';
  }
}

class UserTransactionItem {
  final String id;
  final String itemName;
  final int quantity;
  final double exactQuantity;
  final double unitPrice;
  final double total;
  final String? metadataJson;

  const UserTransactionItem({
    required this.id,
    required this.itemName,
    required this.quantity,
    double? exactQuantity,
    required this.unitPrice,
    required this.total,
    this.metadataJson,
  }) : exactQuantity = exactQuantity ?? quantity * 1.0;

  factory UserTransactionItem.fromJson(Map<String, dynamic> json) {
    final parsedQty = (json['quantity'] as num?)?.toDouble() ?? 1.0;
    final intQty = parsedQty >= 1 ? parsedQty.round() : 1;
    return UserTransactionItem(
      id: json['id']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      quantity: intQty,
      exactQuantity: parsedQty,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      metadataJson: json['metadataJson']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemName': itemName,
      'quantity': exactQuantity,
      'unitPrice': unitPrice,
      'total': total,
      'metadataJson': metadataJson,
    };
  }
}

class UserTransaction {
  final String id;
  final String? userId;
  final String? partnerId;
  final String partnerName;
  final String? transactionType;
  final String? transactionTypeName;
  final String? status;
  final String? statusName;
  final String? externalReference;
  final String? paymentMethodType;
  final String? paymentMethodTypeName;
  final double grossAmount;
  final double discountAmount;
  final double netAmount;
  final double earnedBonusAmount;
  final double spentBonusAmount;
  final double netBonusAmount;
  final DateTime? transactionAt;
  final String? fiscalId;
  final String? notes;
  final String? fileId;
  final String? fileName;
  final List<UserTransactionItem> items;
  final List<WalletHistoryEvent> walletHistories;

  double get bonusAmount => earnedBonusAmount > 0 ? earnedBonusAmount : (netBonusAmount > 0 ? netBonusAmount : 0.0);

  bool get hasFiscalId => fiscalId != null && fiscalId!.trim().isNotEmpty;

  LoyaltyTransactionKind get resolvedTransactionKind {
    final raw = (transactionType ?? transactionTypeName ?? '')
        .trim()
        .toLowerCase();
    final compact = raw.replaceAll(RegExp(r'[\s_-]+'), '');
    switch (compact) {
      case '1':
      case 'purchase':
      case 'alış':
      case 'alis':
      case 'покупка':
        return LoyaltyTransactionKind.purchase;
      case '2':
      case 'bonusgrant':
      case 'bonusəlavəedilməsi':
      case 'bonuselaveedilmesi':
      case 'начислениебонуса':
        return LoyaltyTransactionKind.bonusGrant;
      case '3':
      case 'bonusredemption':
      case 'bonusistifadəsi':
      case 'bonusistifadesi':
      case 'списаниебонуса':
        return LoyaltyTransactionKind.bonusRedemption;
      case '4':
      case 'discountapplied':
      case 'endirimtətbiqi':
      case 'endirimtetbiqi':
      case 'применениескидки':
        return LoyaltyTransactionKind.discountApplied;
      case '5':
      case 'refund':
      case 'geriqaytarma':
      case 'возврат':
        return LoyaltyTransactionKind.refund;
      case '6':
      case 'adjustment':
      case 'düzəliş':
      case 'duzelis':
      case 'корректировка':
        return LoyaltyTransactionKind.adjustment;
    }

    if (raw.contains('purchase') || raw.contains('alış')) {
      return LoyaltyTransactionKind.purchase;
    }
    if (raw.contains('grant') || raw.contains('əlavə')) {
      return LoyaltyTransactionKind.bonusGrant;
    }
    if (raw.contains('redemption') || raw.contains('istifadə')) {
      return LoyaltyTransactionKind.bonusRedemption;
    }
    if (raw.contains('discount') || raw.contains('endirim')) {
      return LoyaltyTransactionKind.discountApplied;
    }
    if (raw.contains('refund') || raw.contains('qaytar')) {
      return LoyaltyTransactionKind.refund;
    }
    if (raw.contains('adjust') || raw.contains('düzəliş')) {
      return LoyaltyTransactionKind.adjustment;
    }
    return LoyaltyTransactionKind.unknown;
  }

  String get displayTransactionType {
    final fromApi = transactionTypeName?.trim();
    if (fromApi != null && fromApi.isNotEmpty) {
      return fromApi;
    }
    return switch (resolvedTransactionKind) {
      LoyaltyTransactionKind.purchase => tr('history_type_purchase'),
      LoyaltyTransactionKind.bonusGrant => tr('history_type_bonus_grant'),
      LoyaltyTransactionKind.bonusRedemption =>
        tr('history_type_bonus_redemption'),
      LoyaltyTransactionKind.discountApplied =>
        tr('history_type_discount_applied'),
      LoyaltyTransactionKind.refund => tr('history_type_refund'),
      LoyaltyTransactionKind.adjustment => tr('history_type_adjustment'),
      LoyaltyTransactionKind.unknown =>
        (transactionType?.trim().isNotEmpty == true)
            ? transactionType!.trim()
            : tr('history_type_purchase'),
    };
  }

  String get receiptTitle {
    return switch (resolvedTransactionKind) {
      LoyaltyTransactionKind.purchase => tr('receipt_sale_title'),
      LoyaltyTransactionKind.refund => tr('receipt_refund_title'),
      _ => tr('receipt_operation_title'),
    };
  }

  String? get fiscalQrUrl {
    final code = fiscalId?.trim();
    if (code == null || code.isEmpty) return null;
    if (code.startsWith('http://') || code.startsWith('https://')) {
      return code;
    }
    return 'https://monitoring.e-kassa.gov.az/#/index?doc=$code';
  }

  const UserTransaction({
    required this.id,
    this.userId,
    this.partnerId,
    required this.partnerName,
    this.transactionType,
    this.transactionTypeName,
    this.status,
    this.statusName,
    this.externalReference,
    this.paymentMethodType,
    this.paymentMethodTypeName,
    required this.grossAmount,
    required this.discountAmount,
    required this.netAmount,
    this.earnedBonusAmount = 0.0,
    this.spentBonusAmount = 0.0,
    this.netBonusAmount = 0.0,
    this.transactionAt,
    this.fiscalId,
    this.notes,
    this.fileId,
    this.fileName,
    this.items = const [],
    this.walletHistories = const [],
  });

  factory UserTransaction.fromJson(Map<String, dynamic> json) {
    final lowerJson = <String, dynamic>{
      for (final entry in json.entries)
        entry.key.trim().toLowerCase(): entry.value,
    };
    final rawFiscalId = (lowerJson['fiscalid'] ??
            lowerJson['fiskalid'] ??
            lowerJson['fiscalcode'] ??
            lowerJson['fiskalcode'] ??
            lowerJson['fiscaldocumentid'])
        ?.toString()
        .trim();
    final cleanFiscalId = (rawFiscalId == null ||
            rawFiscalId.isEmpty ||
            rawFiscalId.toLowerCase() == 'null')
        ? null
        : rawFiscalId;

    List<UserTransactionItem> itemsList = [];
    if (json['items'] is List) {
      itemsList = (json['items'] as List)
          .whereType<Map>()
          .map((item) => UserTransactionItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    List<WalletHistoryEvent> walletHistoriesList = [];
    if (json['walletHistories'] is List) {
      walletHistoriesList = (json['walletHistories'] as List)
          .whereType<Map>()
          .map((item) => WalletHistoryEvent.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    final earnedBonus = (json['earnedBonusAmount'] as num?)?.toDouble() ??
        (json['bonusAmount'] as num?)?.toDouble() ??
        0.0;
    final spentBonus = (json['spentBonusAmount'] as num?)?.toDouble() ?? 0.0;
    final netBonus = (json['netBonusAmount'] as num?)?.toDouble() ??
        (earnedBonus - spentBonus);

    return UserTransaction(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      partnerId: json['partnerId']?.toString(),
      partnerName: json['partnerName']?.toString() ?? '',
      transactionType: json['transactionType']?.toString(),
      transactionTypeName: json['transactionTypeName']?.toString(),
      status: json['status']?.toString(),
      statusName: json['statusName']?.toString(),
      externalReference: json['externalReference']?.toString(),
      paymentMethodType: json['paymentMethodType']?.toString(),
      paymentMethodTypeName: json['paymentMethodTypeName']?.toString(),
      grossAmount: (json['grossAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0.0,
      earnedBonusAmount: earnedBonus,
      spentBonusAmount: spentBonus,
      netBonusAmount: netBonus,
      transactionAt: json['transactionAt'] != null
          ? DateTime.tryParse(json['transactionAt'].toString())
          : null,
      fiscalId: cleanFiscalId,
      notes: json['notes']?.toString(),
      fileId: json['fileId']?.toString(),
      fileName: json['fileName']?.toString(),
      items: itemsList,
      walletHistories: walletHistoriesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'transactionType': transactionType,
      'transactionTypeName': transactionTypeName,
      'status': status,
      'statusName': statusName,
      'externalReference': externalReference,
      'paymentMethodType': paymentMethodType,
      'paymentMethodTypeName': paymentMethodTypeName,
      'grossAmount': grossAmount,
      'discountAmount': discountAmount,
      'netAmount': netAmount,
      'earnedBonusAmount': earnedBonusAmount,
      'spentBonusAmount': spentBonusAmount,
      'netBonusAmount': netBonusAmount,
      'bonusAmount': bonusAmount,
      'transactionAt': transactionAt?.toIso8601String(),
      'fiscalId': fiscalId,
      'notes': notes,
      'fileId': fileId,
      'fileName': fileName,
      'items': items.map((e) => e.toJson()).toList(),
      'walletHistories': walletHistories.map((e) => e.toJson()).toList(),
    };
  }

  String get formattedAmount {
    if (spentBonusAmount > 0) {
      return '- ${spentBonusAmount.toStringAsFixed(2)} ₼';
    }
    if (netAmount > 0) {
      return '- ${netAmount.toStringAsFixed(2)} ₼';
    }
    if (grossAmount > 0) {
      return '- ${grossAmount.toStringAsFixed(2)} ₼';
    }
    if (earnedBonusAmount > 0) {
      return '+ ${earnedBonusAmount.toStringAsFixed(2)} ₼';
    }
    return '0.00 ₼';
  }

  String get formattedBonus {
    if (earnedBonusAmount > 0) {
      return '+ ${earnedBonusAmount.toStringAsFixed(2)} ₼';
    }
    return '0.00 ₼';
  }

  String get formattedDate {
    if (transactionAt == null) return '';
    final dt = transactionAt!;
    final now = DateTime.now();

    final isToday = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;

    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');

    if (isToday) {
      return 'Bu gün, $hourStr:$minStr';
    }
    if (isYesterday) {
      return 'Dünən, $hourStr:$minStr';
    }

    const months = [
      'Yan',
      'Fev',
      'Mar',
      'Apr',
      'May',
      'İyn',
      'İyl',
      'Avq',
      'Sen',
      'Okt',
      'Noy',
      'Dek'
    ];
    final monthName = months[dt.month - 1];
    return '${dt.day.toString().padLeft(2, '0')} $monthName, $hourStr:$minStr';
  }

  String get fullFormattedDate {
    if (transactionAt == null) return '—';
    final dt = transactionAt!;
    const fullMonths = [
      'Yanvar',
      'Fevral',
      'Mart',
      'Aprel',
      'May',
      'İyun',
      'İyul',
      'Avqust',
      'Sentyabr',
      'Oktyabr',
      'Noyabr',
      'Dekabr'
    ];
    final monthName = fullMonths[dt.month - 1];
    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');
    final secStr = dt.second.toString().padLeft(2, '0');
    return '${dt.day} $monthName ${dt.year}, $hourStr:$minStr:$secStr';
  }

  /// UI Transaction modelinə çevirmək üçün köməkçi metod
  Transaction toTransaction() {
    final typeLabel = displayTransactionType;
    final title = partnerName.trim().isNotEmpty
        ? partnerName.trim()
        : typeLabel;

    final subtitle = typeLabel.isNotEmpty
        ? typeLabel
        : (statusName?.trim().isNotEmpty == true
            ? statusName!.trim()
            : tr('history_type_purchase'));

    // 1. Net olan HƏMİŞƏ YUXARIDA yazılır (netAmount > 0 və ya grossAmount > 0 və ya spentBonusAmount > 0):
    final hasSpend = netAmount > 0 || grossAmount > 0 || spentBonusAmount > 0;
    if (hasSpend) {
      final topNet = netAmount > 0
          ? netAmount
          : (grossAmount > 0 ? grossAmount : spentBonusAmount);
      return Transaction(
        id: id,
        title: title,
        subtitle: subtitle,
        amount: '- ${topNet.toStringAsFixed(2)} ₼', // Net olan həmişə yuxarıda
        date: formattedDate,
        type: TransactionType.spend,
        spentBonus: spentBonusAmount > 0 ? spentBonusAmount : null,
        earnedBonus: earnedBonusAmount > 0 ? earnedBonusAmount : null,
      );
    }

    // 2. Yalnız bonus qazanılıbsa (Gəlir kimi):
    if (earnedBonusAmount > 0) {
      return Transaction(
        id: id,
        title: title,
        subtitle: subtitle,
        amount: '+ ${earnedBonusAmount.toStringAsFixed(2)} ₼',
        date: formattedDate,
        type: TransactionType.earn,
        earnedBonus: earnedBonusAmount,
      );
    }

    // 3. Endirim tətbiqi:
    if (discountAmount > 0) {
      return Transaction(
        id: id,
        title: title,
        subtitle: subtitle,
        amount: '- ${discountAmount.toStringAsFixed(2)} ₼',
        date: formattedDate,
        type: TransactionType.discount,
      );
    }

    return Transaction(
      id: id,
      title: title,
      subtitle: subtitle,
      amount: '0.00 ₼',
      date: formattedDate,
      type: TransactionType.spend,
    );
  }
}
