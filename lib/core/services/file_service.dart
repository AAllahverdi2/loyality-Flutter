import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';

/// Fayl yüklənməsi nəticəsi modeli
class FileUploadResponse {
  final bool isSuccess;
  final String? fileId;
  final List<String> fileIds;
  final String? fileName;
  final String? fileUrl;
  final String? errorMessage;
  final int? statusCode;
  final dynamic rawData;

  const FileUploadResponse({
    this.isSuccess = false,
    this.fileId,
    this.fileIds = const [],
    this.fileName,
    this.fileUrl,
    this.errorMessage,
    this.statusCode,
    this.rawData,
  });

  factory FileUploadResponse.fromResponse(Response response) {
    final statusCode = response.statusCode;
    final data = response.data;

    if (statusCode == 200 || statusCode == 201) {
      if (data is Map) {
        final result = data['result'] ?? data['data'];

        // 1. result List formatındadırsa (çünki Files massiv kimi göndərilir)
        if (result is List && result.isNotEmpty) {
          final List<String> ids = [];
          String? firstName;
          for (final item in result) {
            if (item is String) {
              ids.add(item);
            } else if (item is Map) {
              final id = (item['id'] ??
                      item['fileId'] ??
                      item['attachId'] ??
                      item['avatarFileId'])
                  ?.toString();
              if (id != null && id.isNotEmpty) ids.add(id);
              firstName ??= (item['fileName'] ?? item['name'])?.toString();
            }
          }
          final primaryId = ids.isNotEmpty ? ids.first : null;
          return FileUploadResponse(
            isSuccess: true,
            fileId: primaryId,
            fileIds: ids,
            fileName: firstName,
            statusCode: statusCode,
            rawData: data,
          );
        }

        // 2. result birbaşa String ID-dirsə
        if (result is String && result.isNotEmpty) {
          return FileUploadResponse(
            isSuccess: true,
            fileId: result,
            fileIds: [result],
            statusCode: statusCode,
            rawData: data,
          );
        }

        // 3. result Map formatındadırsa
        if (result is Map) {
          final id = (result['id'] ??
                  result['attachId'] ??
                  result['fileId'] ??
                  result['avatarFileId'])
              ?.toString();
          final name =
              (result['fileName'] ?? result['name'] ?? result['filename'])
                  ?.toString();
          final url =
              (result['url'] ?? result['filePath'] ?? result['downloadUrl'])
                  ?.toString();
          return FileUploadResponse(
            isSuccess: true,
            fileId: id,
            fileIds: id != null ? [id] : const [],
            fileName: name,
            fileUrl: url,
            statusCode: statusCode,
            rawData: data,
          );
        }

        // 4. Response birbaşa data daxilində id saxlayırsa
        final id = (data['id'] ??
                data['attachId'] ??
                data['fileId'] ??
                data['avatarFileId'])
            ?.toString();
        return FileUploadResponse(
          isSuccess: true,
          fileId: id,
          fileIds: id != null ? [id] : const [],
          fileName: (data['fileName'] ?? data['name'])?.toString(),
          fileUrl: (data['url'] ?? data['filePath'])?.toString(),
          statusCode: statusCode,
          rawData: data,
        );
      } else if (data is List && data.isNotEmpty) {
        final List<String> ids = data.map((e) => e.toString()).toList();
        return FileUploadResponse(
          isSuccess: true,
          fileId: ids.first,
          fileIds: ids,
          statusCode: statusCode,
          rawData: data,
        );
      } else if (data is String && data.isNotEmpty) {
        return FileUploadResponse(
          isSuccess: true,
          fileId: data,
          fileIds: [data],
          statusCode: statusCode,
          rawData: data,
        );
      }
      return FileUploadResponse(
        isSuccess: true,
        statusCode: statusCode,
        rawData: data,
      );
    }

    String? error;
    if (data is Map) {
      error = data['errorMessage']?.toString() ??
          data['message']?.toString() ??
          data['title']?.toString();
    }
    return FileUploadResponse(
      isSuccess: false,
      errorMessage: error ?? 'Fayl yüklənərkən xəta baş verdi',
      statusCode: statusCode,
      rawData: data,
    );
  }

  factory FileUploadResponse.failure(
    String message, {
    int? statusCode,
    dynamic error,
  }) {
    return FileUploadResponse(
      isSuccess: false,
      errorMessage: message,
      statusCode: statusCode,
      rawData: error,
    );
  }
}

/// Fayl əməliyyatları üçün servis:
/// - POST /api/File/upload (FormData: 'Files': [files], 'Type': string)
/// - GET /api/File/download/{attachId}
/// - DELETE /api/File/delete/{id}
class FileService {
  final ApiClient _client = ApiClient.instance;

  /// Authorization başlığını əldə etmək üçün köməkçi xassə
  Map<String, String> get authHeaders => _client.authHeaders;

  /// Faylın yüklənməsi üçün tam URL-i əldə etmək
  /// Nümunə: http://192.168.100.173/api/File/download/{attachId}
  String getFileUrl(String attachId) {
    return '${ApiEndpoints.baseUrl}${ApiEndpoints.fileDownload(attachId)}';
  }

  /// 1. Tək faylı serverə yükləmək (POST /api/File/upload)
  /// [file] - dart:io File obyekti
  /// [type] - Backend üçün Type parametri (default: 'string')
  /// [fileName] - Fayl adı (boş olarsa faylın öz adından götürülür)
  Future<FileUploadResponse> uploadFile(
    File file, {
    String type = 'string',
    String? fileName,
    ProgressCallback? onSendProgress,
  }) async {
    return uploadMultipleFiles(
      [file],
      type: type,
      fileNames: fileName != null ? [fileName] : null,
      onSendProgress: onSendProgress,
    );
  }

  /// 1b. Çoxsaylı faylları serverə yükləmək (POST /api/File/upload)
  /// Backend formData parametrləri:
  /// - 'Files': array of files
  /// - 'Type': string
  Future<FileUploadResponse> uploadMultipleFiles(
    List<File> files, {
    String type = 'string',
    List<String>? fileNames,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('Type', type));

      for (int i = 0; i < files.length; i++) {
        final f = files[i];
        final name = (fileNames != null && i < fileNames.length)
            ? fileNames[i]
            : f.path.split(Platform.pathSeparator).last;

        final multipartFile = await MultipartFile.fromFile(
          f.path,
          filename: name,
        );

        formData.files.add(MapEntry('Files', multipartFile));
      }

      debugPrint('📤 [FAYLLAR YÜKLƏNİR]: ${files.length} fayl, Type=$type');
      final options = Options(
        headers: {
          ..._client.authHeaders,
        },
      );
      options.headers?.remove('Content-Type');
      options.headers?.remove('content-type');

      final response = await _client.dio.post(
        ApiEndpoints.fileUpload,
        data: formData,
        options: options,
        onSendProgress: onSendProgress,
      );

      debugPrint('✅ [FAYL YÜKLƏNDİ]: ${response.statusCode} - ${response.data}');
      return FileUploadResponse.fromResponse(response);
    } on DioException catch (e) {
      debugPrint('❌ [FAYL YÜKLƏNMƏ XƏTASI]: ${e.response?.statusCode} - ${e.response?.data}');
      if (e.response != null) {
        return FileUploadResponse.fromResponse(e.response!);
      }
      return FileUploadResponse.failure(e.message ?? 'Şəbəkə xətası baş verdi');
    } catch (e) {
      debugPrint('❌ [GÖZLƏNİLMƏZ FAYL YÜKLƏNMƏ XƏTASI]: $e');
      return FileUploadResponse.failure(e.toString());
    }
  }

  /// 1c. Fayl yoluna görə serverə yükləmək (POST /api/File/upload)
  Future<FileUploadResponse> uploadFilePath(
    String filePath, {
    String type = 'string',
    String? fileName,
    ProgressCallback? onSendProgress,
  }) async {
    return uploadFile(
      File(filePath),
      type: type,
      fileName: fileName,
      onSendProgress: onSendProgress,
    );
  }

  /// 1d. Baytlar (bytes) vasitəsilə faylı yükləmək (POST /api/File/upload)
  Future<FileUploadResponse> uploadBytes(
    List<int> bytes, {
    required String fileName,
    String type = 'string',
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: fileName,
      );

      final formData = FormData();
      formData.fields.add(MapEntry('Type', type));
      formData.files.add(MapEntry('Files', multipartFile));

      debugPrint('📤 [BAYT FAYL YÜKLƏNİR]: $fileName (${bytes.length} bytes), Type=$type');
      final options = Options(
        headers: {
          ..._client.authHeaders,
        },
      );
      options.headers?.remove('Content-Type');
      options.headers?.remove('content-type');

      final response = await _client.dio.post(
        ApiEndpoints.fileUpload,
        data: formData,
        options: options,
        onSendProgress: onSendProgress,
      );

      debugPrint('✅ [FAYL YÜKLƏNDİ]: ${response.statusCode} - ${response.data}');
      return FileUploadResponse.fromResponse(response);
    } on DioException catch (e) {
      debugPrint('❌ [FAYL YÜKLƏNMƏ XƏTASI]: ${e.response?.statusCode} - ${e.response?.data}');
      if (e.response != null) {
        return FileUploadResponse.fromResponse(e.response!);
      }
      return FileUploadResponse.failure(e.message ?? 'Şəbəkə xətası baş verdi');
    } catch (e) {
      debugPrint('❌ [GÖZLƏNİLMƏZ FAYL YÜKLƏNMƏ XƏTASI]: $e');
      return FileUploadResponse.failure(e.toString());
    }
  }

  /// 2. Faylı baytlar olaraq yükləyib əldə etmək (GET /api/File/download/{attachId})
  /// Avtomatik olaraq `Authorization: Bearer <token>` başlığı əlavə edilir.
  Future<List<int>?> downloadFileBytes(
    String attachId, {
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      debugPrint('📥 [FAYL ENDİRİLİR (BYTES)]: $attachId');
      final response = await _client.dio.get<List<int>>(
        ApiEndpoints.fileDownload(attachId),
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: onReceiveProgress,
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('✅ [FAYL ENDİRİLDİ]: ${response.data!.length} bytes');
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [FAYL ENDİRMƏ XƏTASI]: $e');
      rethrow;
    }
  }

  /// 2b. Faylı birbaşa yerli yaddaşa yükləmək (GET /api/File/download/{attachId})
  Future<bool> downloadToFile(
    String attachId,
    String savePath, {
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      debugPrint('📥 [FAYL ENDİRİLİR (SAVE_PATH)]: $attachId -> $savePath');
      final response = await _client.dio.download(
        ApiEndpoints.fileDownload(attachId),
        savePath,
        onReceiveProgress: onReceiveProgress,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [FAYL ENDİRMƏ XƏTASI]: $e');
      return false;
    }
  }

  /// 3. Faylı silmək (DELETE /api/File/delete/{id})
  /// [id] - Faylın və ya attachment-in UUID identifikatoru
  Future<bool> deleteFile(String id) async {
    try {
      debugPrint('🗑️ [FAYL SİLİNİR]: $id');
      final response = await _client.delete(ApiEndpoints.fileDelete(id));
      debugPrint('✅ [FAYL SİLİNDİ]: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('❌ [FAYL SİLMƏ XƏTASI]: $e');
      rethrow;
    }
  }

  /// 3b. Fayl silmə sorğusunun tam Response nəticəsini almaq (DELETE /api/File/delete/{id})
  Future<Response> deleteFileRaw(String id) async {
    return await _client.delete(ApiEndpoints.fileDelete(id));
  }
}
