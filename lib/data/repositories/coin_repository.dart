// lib/data/repositories/coin_repository.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/coin.dart';

class CoinRepository extends ChangeNotifier {
  List<Coin> _coins = [];
  bool _isLoading = false;
  final Dio _dio = Dio();
  late final CacheOptions _baseOptions;
  late final HiveCacheStore _cacheStore;
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  List<Coin> get coins => _coins;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;

  CoinRepository() {
    _setupCache();
    _clearOldCache();
    _startAutoRefresh();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    if (kIsWeb) {
      _isOnline = true;
      notifyListeners();
      return;
    }

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _updateOnlineStatus(connectivityResult);

      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
        _updateOnlineStatus(results);
      });

      // FORCE ONLINE IF MOBILE/WIFI
      if (connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi)) {
        _isOnline = true;
        notifyListeners();
        fetchCoins(forceRefresh: true);
      }
    } catch (e) {
      _isOnline = true;
      notifyListeners();
    }
  }

  void _updateOnlineStatus(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      notifyListeners();
      if (_isOnline) fetchCoins(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _setupCache() {
    final cacheDir = Hive.box('dio_cache').path ?? '';
    _cacheStore = HiveCacheStore(cacheDir);

    _baseOptions = CacheOptions(
      store: _cacheStore,
      policy: CachePolicy.request,
      maxStale: const Duration(days: 7),
    );

    _dio.interceptors.add(DioCacheInterceptor(options: _baseOptions));
  }

  Future<void> _clearOldCache() async {
    try {
      await _cacheStore.clean();
    } catch (e) {}
  }

  void _startAutoRefresh() {
    Timer.periodic(const Duration(seconds: 60), (_) {
      if (_isOnline) fetchCoins(forceRefresh: false);
    });
  }

  Future<void> fetchCoins({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final policy = forceRefresh ? CachePolicy.noCache : CachePolicy.request;
      final options = _baseOptions.copyWith(policy: policy).toOptions();

      final response = await _dio.get(
        'https://api.coingecko.com/api/v3/coins/markets',
        queryParameters: {
          'vs_currency': 'usd',
          'order': 'market_cap_desc',
          'per_page': 100,
          'page': 1,
          'sparkline': true,
        },
        options: options,
      );

      final List data = response.data;
      _coins = data.map((json) => Coin.fromJson(json)).toList();
    } on DioException catch (e) {
      debugPrint('Network error: $e');
      await _loadFromCache();
    } catch (e) {
      debugPrint('Unexpected error: $e');
      await _loadFromCache();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final key = _dio.getUri(Uri(
        scheme: 'https',
        host: 'api.coingecko.com',
        path: '/api/v3/coins/markets',
        queryParameters: {
          'vs_currency': 'usd',
          'order': 'market_cap_desc',
          'per_page': '100',
          'page': '1',
          'sparkline': 'true',
        },
      )).toString();

      final cached = await _cacheStore.get(key);
      if (cached?.content != null) {
        final List data = cached!.content!;
        _coins = data.map((json) => Coin.fromJson(json)).toList();
      }
    } catch (e) {}
  }
}