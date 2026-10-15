import 'package:dio/dio.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';

class HomeService {
  final ApiClient _client = ApiClient.instance;

  // Ana səhifənin bütün məlumatlarını gətirmək
  Future<Response> getHomeData() async {
    try {
      final response = await _client.get(ApiEndpoints.homeData);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Banner-ləri gətirmək
  Future<Response> getBanners() async {
    try {
      final response = await _client.get(ApiEndpoints.banners);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Kateqoriyaları gətirmək
  Future<Response> getCategories() async {
    try {
      final response = await _client.get(ApiEndpoints.categories);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Xüsusi təkliflər / Kampaniyalar
  Future<Response> getFeaturedOffers() async {
    try {
      final response = await _client.get(ApiEndpoints.featuredOffers);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
