// lib/data/repositories/coin_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/coin.dart';

enum DataState { loading, loaded }

class CoinRepository extends ChangeNotifier {
  List<Coin> _coins = [];
  DataState _dataState = DataState.loading;
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final Dio _dio = Dio();

  List<Coin> get coins => _coins;
  DataState get dataState => _dataState;
  bool get isOnline => _isOnline;

  CoinRepository() {
    _init();
  }

  Future<void> _init() async {
    await _setupCache(); // Setup Hive boxes FIRST
    await _checkConnectivity();
    await _loadFromCache(); // Then try to load cached coins

    if (_isOnline) {
      await _fetchOnline(); // FETCH + SAVE
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
      // Note: We're not using HiveCacheStore for Dio interceptor since it has permission issues
      // Instead, we'll rely on our own Hive 'coins' box for offline storage
      
      (_dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };

      // Initialize coins Hive box for reliable offline storage
      if (!Hive.isBoxOpen('coins')) {
        await Hive.openBox('coins');
      }
      
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
      _isOnline = result != ConnectivityResult.none;
    } catch (e) {
      _isOnline = false;
    }
  }

  Future<void> _loadFromCache() async {
    try {
      // Try to load coins from the Hive 'coins' box (reliable offline storage)
      try {
        debugPrint('Checking if coins box is open: ${Hive.isBoxOpen('coins')}');
        if (!Hive.isBoxOpen('coins')) {
          debugPrint('Coins box not open, attempting to open it...');
          await Hive.openBox('coins');
        }
        
        final box = Hive.box('coins');
        final cachedJson = box.get('coin_list_json'); // Store as JSON string
        debugPrint('Retrieved cached JSON from box: ${cachedJson != null ? 'found (length=${(cachedJson as String).length})' : 'null'}');
        
        if (cachedJson != null && cachedJson is String) {
          try {
            final List data = jsonDecode(cachedJson) as List;
            _coins = data.map((json) => Coin.fromJson(json)).toList();
            debugPrint('Loaded ${_coins.length} coins from Hive backup');
            return;
          } catch (parseError) {
            debugPrint('Failed to parse cached JSON: $parseError');
          }
        }
      } catch (e) {
        debugPrint('Hive coins backup read failed: $e');
      }

      debugPrint('No cached coins available');
    } catch (e) {
      debugPrint('Cache load failed: $e');
    }
  }

  Future<void> _fetchOnline() async {
    _updateState(DataState.loading);

    try {
      final response = await _dio.get(
        'https://api.coingecko.com/api/v3/coins/markets',
        queryParameters: {
          'vs_currency': 'usd',
          'order': 'market_cap_desc',
          'per_page': 100,
          'page': 1,
          'sparkline': true,
        },
      ).timeout(const Duration(seconds: 10));

      final List data = response.data;
      _coins = data.map((json) => Coin.fromJson(json)).toList();
      debugPrint('Fetched ${_coins.length} coins online');
      
      // Persist coins to Hive 'coins' box for reliable offline use (as JSON string)
      try {
        debugPrint('Attempting to save coins to Hive...');
        if (Hive.isBoxOpen('coins')) {
          final box = Hive.box('coins');
          final jsonString = jsonEncode(data);
          debugPrint('Box is open, putting data (key=coin_list_json, size=${jsonString.length})');
          await box.put('coin_list_json', jsonString);
          // Verify it was written
          final verify = box.get('coin_list_json');
          debugPrint('Verification read: ${verify != null ? 'SUCCESS (length=${(verify as String).length})' : 'FAILED (null)'}');
          debugPrint('Wrote coins to Hive backup as JSON (size=${jsonString.length} bytes, count=${_coins.length})');
        } else {
          debugPrint('ERROR: Coins box is NOT open when trying to save!');
        }
      } catch (e) {
        debugPrint('Failed to write coins to Hive backup: $e');
      }
      
      _updateState(DataState.loaded);
    } catch (e) {
      debugPrint('Network failed: $e → using cache');
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
    super.dispose();
  }
}