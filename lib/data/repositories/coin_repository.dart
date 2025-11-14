// lib/data/repositories/coin_repository.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/coin.dart';

enum DataState { loading, loaded }

class CoinRepository extends ChangeNotifier {
  List<Coin> _coins = [];
  DataState _dataState = DataState.loading;
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final Dio _dio = Dio(); // FIXED: Dio21 → Dio
  CacheOptions? _cacheOptions;
  HiveCacheStore? _cacheStore;

  List<Coin> get coins => _coins;
  DataState get dataState => _dataState;
  bool get isOnline => _isOnline;

  CoinRepository() {
    _init();
  }

  Future<void> _init() async {
    await _setupCache();
    await _loadFromCache();
    await _checkConnectivity();

    if (_isOnline) {
      await _fetchOnline();
    } else {
      _updateState(DataState.loaded);
    }

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final nowOnline = results.any((r) => r != ConnectivityResult.none);
      if (nowOnline && !_isOnline) {
        _isOnline = true;
        _fetchOnline();
      } else if (!nowOnline && _isOnline) {
        _isOnline = false;
      }
    });
  }

  Future<void> _setupCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/dio_cache.hive';
      _cacheStore = HiveCacheStore(path);

      _cacheOptions = CacheOptions(
        store: _cacheStore,
        policy: CachePolicy.refreshForceCache, // ALWAYS HIT CACHE ON ERROR
        maxStale: const Duration(days: 30),
      );

      (_dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };

      _dio.interceptors.add(DioCacheInterceptor(options: _cacheOptions!));
      debugPrint('Cache setup complete');
    } catch (e) {
      debugPrint('Cache setup failed: $e');
    }
  }

  Future<void> _checkConnectivity() async {
    if (kIsWeb) {
      _isOnline = true;
      return;
    }
    try {
      final result = await Connectivity().checkConnectivity();
      _isOnline = result.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      _isOnline = false;
    }
  }

  Future<void> _loadFromCache() async {
    if (_cacheStore == null || _cacheOptions == null) return;

    try {
      final key = _getCacheKey();
      final cached = await _cacheStore!.get(key);
      if (cached?.content != null) {
        final List data = cached!.content!;
        _coins = data.map((json) => Coin.fromJson(json)).toList();
        debugPrint('Loaded ${_coins.length} coins from cache');
      } else {
        debugPrint('No cached data found');
      }
    } catch (e) {
      debugPrint('Cache load failed: $e');
    }
  }

  String _getCacheKey() {
    return _dio.getUri(Uri(
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
  }

  Future<void> _fetchOnline() async {
    if (_cacheOptions == null) return;

    _updateState(DataState.loading);

    try {
      final options = _cacheOptions!.copyWith(policy: CachePolicy.refresh).toOptions();

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
      ).timeout(const Duration(seconds: 10));

      final List data = response.data;
      _coins = data.map((json) => Coin.fromJson(json)).toList();
      debugPrint('Fetched ${_coins.length} coins online');
      _updateState(DataState.loaded);
    } catch (e) {
      debugPrint('Network failed, using cache: $e');
      await _loadFromCache();
      _updateState(DataState.loaded);
    }
  }

  Future<void> refresh() async {
    await _loadFromCache();
    if (_isOnline) {
      await _fetchOnline();
    } else {
      _updateState(DataState.loaded);
    }
  }

  void _updateState(DataState state) {
    if (_dataState != state) {
      _dataState = state;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _cacheStore?.close();
    super.dispose();
  }
}