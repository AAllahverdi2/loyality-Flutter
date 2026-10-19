import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';

class PinCodeService {
  PinCodeService._internal();
  static final PinCodeService instance = PinCodeService._internal();

  final ApiClient _client = ApiClient.instance;

  /// Yeni 4 rəqəmli PIN kod təyin etmək (/api/Users/myPinCode/set)
  Future<bool> setPinCode({
    required String pinCode,
    required String confirmPinCode,
  }) async {
    try {
      final response = await _client.post(
        ApiEndpoints.setMyPinCode,
        data: {
          'pinCode': pinCode,
          'confirmPinCode': confirmPinCode,
        },
      );

      debugPrint('📦 [SET_PIN_CODE CAVABI]: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map && data['isSuccess'] == false) {
          final msg = data['errorMessage']?.toString() ?? 'PIN kod təyin edilə bilmədi.';
          throw Exception(msg);
        }
        // Uğurlu olduqda yerli yaddaşa da saxlayırıq
        await TokenStorage.setPinCode(pinCode);
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('❌ [SET_PIN_CODE DIO XƏTASI]: ${e.response?.data}');
      String errorMsg = 'PIN kod təyin edilərkən xəta baş verdi.';
      if (e.response?.data != null && e.response?.data is Map) {
        errorMsg = e.response?.data['errorMessage']?.toString() ??
            e.response?.data['message']?.toString() ??
            errorMsg;
      }
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('❌ [SET_PIN_CODE XƏTA]: $e');
      rethrow;
    }
  }

  /// Daxil edilmiş 4 rəqəmli PIN kodu yoxlamaq (/api/Users/myPinCode/verify)
  Future<bool> verifyPinCode(String pinCode) async {
    try {
      final response = await _client.post(
        ApiEndpoints.verifyMyPinCode,
        data: {
          'pinCode': pinCode,
        },
      );

      debugPrint('📦 [VERIFY_PIN_CODE CAVABI]: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          if (data['isSuccess'] == true) {
            return true;
          } else {
            final msg = data['errorMessage']?.toString() ?? 'Daxil edilən PIN kod yanlışdır.';
            throw Exception(msg);
          }
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('❌ [VERIFY_PIN_CODE DIO XƏTASI]: ${e.response?.data}');
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        // İnternet problemi olarsa yerli yaddaşla ehtiyat yoxlama
        final localPin = await TokenStorage.getPinCode();
        if (localPin != null && localPin.isNotEmpty && localPin == pinCode) {
          return true;
        }
      }

      String errorMsg = 'Daxil edilən PIN kod yanlışdır.';
      if (e.response?.data != null && e.response?.data is Map) {
        errorMsg = e.response?.data['errorMessage']?.toString() ??
            e.response?.data['message']?.toString() ??
            errorMsg;
      }
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('❌ [VERIFY_PIN_CODE XƏTA]: $e');
      rethrow;
    }
  }

  /// PIN kodun mövcudluğunu yoxlamaq
  Future<bool> hasPinCode() async {
    return await TokenStorage.hasPinCode();
  }

  /// PIN kodu serverdən və yerli yaddaşdan silmək (/api/Users/myPinCode/remove)
  Future<bool> removePinCode() async {
    try {
      final response = await _client.delete(
        ApiEndpoints.removeMyPinCode,
      );

      debugPrint('📦 [REMOVE_PIN_CODE CAVABI]: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        final data = response.data;
        if (data is Map && data['isSuccess'] == false) {
          final msg = data['errorMessage']?.toString() ?? 'PIN kod silinə bilmədi.';
          throw Exception(msg);
        }
        // Uğurlu olduqda yerli yaddaşdan da silirik
        await TokenStorage.removePinCode();
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('❌ [REMOVE_PIN_CODE DIO XƏTASI]: ${e.response?.data}');
      String errorMsg = 'PIN kod silinərkən xəta baş verdi.';
      if (e.response?.data != null && e.response?.data is Map) {
        errorMsg = e.response?.data['errorMessage']?.toString() ??
            e.response?.data['message']?.toString() ??
            errorMsg;
      }
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('❌ [REMOVE_PIN_CODE XƏTA]: $e');
      rethrow;
    }
  }
}
