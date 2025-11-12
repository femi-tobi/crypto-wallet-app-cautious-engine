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

  late final CacheOptions _baseCacheOptions;

  CoinRepository() {
    _initCache();
  }

  Future<void> _initCache() async {
    // Let Hive auto-pick storage
    // Web: IndexedDB
    // Mobile: App documents
    final cacheStore = HiveCacheStore(null);

    _baseCacheOptions = CacheOptions(
      store: cacheStore,
      policy: CachePolicy.refresh,
      maxStale: const Duration(days: 1),
    );

    _dio.interceptors.add(DioCacheInterceptor(options: _baseCacheOptions));
  }

  List<Coin> get coins => _coins;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCoins({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final requestOptions = _baseCacheOptions.copyWith(
        policy: forceRefresh ? CachePolicy.noCache : CachePolicy.refresh,
      ).toOptions();

      final response = await _dio.get(
        '/coins/markets',
        queryParameters: {
          'vs_currency': 'usd',
          'order': 'market_cap_desc',
          'per_page': 100,
          'page': 1,
          'sparkline': false,
        },
        options: requestOptions,
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
          .toList();
    } catch (_) {
      return [];
    }
  }
}