import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/features/history/models/wallet_balance.dart';

class WalletService {
  final ApiClient _client = ApiClient.instance;

  static WalletBalance? cachedBalance;
  static final ValueNotifier<WalletBalance?> balanceNotifier =
      ValueNotifier<WalletBalance?>(null);

  /// Şəxsi cüzdan balansını gətirir (/api/Wallets/myBalance)
  Future<WalletBalance?> getMyBalance({bool forceRefresh = false}) async {
    if (!forceRefresh && cachedBalance != null) {
      return cachedBalance;
    }

    try {
      final response = await _client.get(ApiEndpoints.walletMyBalance);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map) {
          final result = data['result'] ?? data['data'];
          if (result is Map) {
            final balance = WalletBalance.fromJson(
              Map<String, dynamic>.from(result),
            );
            cachedBalance = balance;
            balanceNotifier.value = balance;
            return balance;
          }
        }
      }
      return cachedBalance;
    } on DioException catch (e) {
      debugPrint('Cüzdan balansı gətirilərkən Dio xətası: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Cüzdan balansı gətirilərkən xəta: $e');
      rethrow;
    }
  }
}
