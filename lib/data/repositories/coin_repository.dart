import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';

import '../models/coin.dart';

class CoinRepository with ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://api.coingecko.com/api/v3'));

  List<Coin> _coins = [];
  bool _isLoading = false;
  String? _error;

  CoinRepository() {
    final cacheDir = Directory.systemTemp.createTempSync('coingecko_cache');
    final cacheStore = HiveCacheStore(cacheDir.path);

    _dio.interceptors.add(
      DioCacheInterceptor(
        options: CacheOptions(
          store: cacheStore,
          policy: CachePolicy.refresh,
          maxStale: const Duration(days: 1),
        ),
      ),
    );
  }

  List<Coin> get coins => _coins;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCoins({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Extract store from existing interceptor
      final interceptor = _dio.interceptors.firstWhere((i) => i is DioCacheInterceptor) as DioCacheInterceptor;
      final store = interceptor.options.store;

      final cacheOptions = CacheOptions(
        store: store,
        policy: forceRefresh ? CachePolicy.forceRefresh : CachePolicy.refresh,
        maxStale: const Duration(days: 1),
      );

      final response = await _dio.get(
        '/coins/markets',
        queryParameters: {
          'vs_currency': 'usd',
          'order': 'market_cap_desc',
          'per_page': 100,
          'page': 1,
          'sparkline': false,
        },
        options: cacheOptions.toOptions(),
      );

      final List data = response.data as List;
      _coins = data.map((e) => Coin.fromJson(e)).toList();
    } on DioException catch (e) {
      _error = e.response?.statusCode == 429
          ? 'Rate limited. Try again later.'
          : e.message ?? 'Network error';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<FlSpot>> getPriceHistory(String coinId) async {
    try {
      final resp = await _dio.get(
        '/coins/$coinId/market_chart',
        queryParameters: {'vs_currency': 'usd', 'days': '7'},
      );
      final List prices = resp.data['prices'] as List;
      return prices
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), (e.value[1] as num).toDouble()))
          .toList(); // FIXED: Added .toList() and closed all brackets
    } catch (_) {
      return [];
    }
  }
}