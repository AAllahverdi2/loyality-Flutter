class WalletBalance {
  final String walletId;
  final String userId;
  final double coinBalance;
  final bool isActive;

  const WalletBalance({
    required this.walletId,
    required this.userId,
    required this.coinBalance,
    required this.isActive,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      walletId: json['walletId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      coinBalance: (json['coinBalance'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'walletId': walletId,
      'userId': userId,
      'coinBalance': coinBalance,
      'isActive': isActive,
    };
  }

  /// Balansı səliqəli string kimi qaytarır (məsələn: 529.5 və ya 500)
  String get formattedBalance {
    if (coinBalance % 1 == 0) {
      return coinBalance.toInt().toString();
    }
    return coinBalance.toString();
  }
}
