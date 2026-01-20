import 'dart:convert' show json;

import 'package:flutter/cupertino.dart';
import 'package:pharmatest/pharmacy_model.dart'; // Updated import
import 'package:pharmatest/pharmacy_service.dart'; // Updated import
import 'package:shared_preferences/shared_preferences.dart';

class PharmacyRepository {
  final SharedPreferences prefs;
  final PharmacyService _service = PharmacyService();

  Map<String, List<String>>? _regionsAndTowns;
  DateTime? _regionsLastFetchTime; // Specific last fetch time for regions

  final Map<String, Map<String, List<Pharmacy>>> _pharmacyCache =
      {}; // Cache for pharmacies: region -> town -> list of pharmacies
  final Map<String, Map<String, DateTime>> _pharmacyLastFetchTimes =
      {}; // Cache for last fetch times of pharmacies: region -> town -> DateTime

  PharmacyRepository(this.prefs);

  Future<Map<String, List<String>>> getRegionsAndTowns() async {
    // 1. Check in-memory cache
    if (_regionsAndTowns != null &&
        _regionsLastFetchTime != null &&
        !_isCacheExpired(_regionsLastFetchTime!)) {
      return _regionsAndTowns!;
    }

    // 2. Check persistent storage (SharedPreferences)
    final cachedData = prefs.getString('regionsAndTowns');
    final lastFetchMillis = prefs.getInt('regionsLastFetchTime');

    if (cachedData != null &&
        lastFetchMillis != null &&
        !_isCacheExpired(
          DateTime.fromMillisecondsSinceEpoch(lastFetchMillis),
        )) {
      try {
        final decodedData = json.decode(cachedData);
        if (decodedData is Map<String, dynamic>) {
          _regionsAndTowns = decodedData.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          );
          _regionsLastFetchTime = DateTime.fromMillisecondsSinceEpoch(
            lastFetchMillis,
          );
          return _regionsAndTowns!;
        }
      } catch (e) {
        debugPrint('Error decoding cached regions and towns: $e');
        // Fall through to fetch from service if cache is corrupted
      }
    }

    // 3. Fetch from service
    try {
      _regionsAndTowns = await _service.fetchRegionsAndTowns();
      _regionsLastFetchTime = DateTime.now();

      // 4. Save to persistent storage
      await prefs.setString('regionsAndTowns', json.encode(_regionsAndTowns));
      await prefs.setInt(
        'regionsLastFetchTime',
        _regionsLastFetchTime!.millisecondsSinceEpoch,
      );

      return _regionsAndTowns!;
    } catch (e) {
      debugPrint('Error fetching regions: $e. Trying fallback to stale cache.');
      // Fallback: If network fails (site offline), return stale cache if available
      if (cachedData != null) {
        try {
          final decodedData = json.decode(cachedData);
          if (decodedData is Map<String, dynamic>) {
            _regionsAndTowns = decodedData.map(
              (key, value) => MapEntry(key, List<String>.from(value)),
            );
            return _regionsAndTowns!;
          }
        } catch (_) {}
      }
      rethrow; // No cache and network failed
    }
  }

  Future<List<Pharmacy>> getPharmacies(String region, String town) async {
    // Check persistent storage first
    final cacheKey = 'pharmacies_${region}_$town';
    final pharmacyLastFetchKey = 'pharmacy_last_fetch_${region}_$town';

    // 1. Check in-memory cache
    final inMemoryPharmacies = _pharmacyCache[region]?[town];
    final inMemoryLastFetch = _pharmacyLastFetchTimes[region]?[town];

    if (inMemoryPharmacies != null &&
        inMemoryLastFetch != null &&
        !_isCacheExpired(inMemoryLastFetch)) {
      return inMemoryPharmacies;
    }

    // 2. Check persistent storage (SharedPreferences)
    final cachedData = prefs.getString(cacheKey);
    final lastFetchMillis = prefs.getInt(pharmacyLastFetchKey);

    if (cachedData != null &&
        lastFetchMillis != null &&
        !_isCacheExpired(
          DateTime.fromMillisecondsSinceEpoch(lastFetchMillis),
        )) {
      try {
        final decodedData = json.decode(cachedData);
        if (decodedData is List) {
          final loadedPharmacies = decodedData
              .map((item) => Pharmacy.fromJson(item))
              .toList();
          _pharmacyCache.putIfAbsent(region, () => {})[town] = loadedPharmacies;
          _pharmacyLastFetchTimes.putIfAbsent(region, () => {})[town] =
              DateTime.fromMillisecondsSinceEpoch(lastFetchMillis);
          return loadedPharmacies;
        }
      } catch (e) {
        debugPrint('Error decoding cached pharmacies for $region/$town: $e');
        // Fall through to fetch from service if cache is corrupted
      }
    }

    // 3. Fetch from service
    try {
      final pharmacies = await _service.fetchPharmacies(region, town);
      final now = DateTime.now();

      // Update in-memory cache
      _pharmacyCache.putIfAbsent(region, () => {})[town] = pharmacies;
      _pharmacyLastFetchTimes.putIfAbsent(region, () => {})[town] = now;

      // 4. Save to persistent storage
      await prefs.setString(
        cacheKey,
        json.encode(pharmacies.map((p) => p.toJson()).toList()),
      );
      await prefs.setInt(pharmacyLastFetchKey, now.millisecondsSinceEpoch);

      return pharmacies;
    } catch (e) {
      debugPrint(
        'Error fetching pharmacies: $e. Trying fallback to stale cache.',
      );
      // Fallback: If network fails (site offline), return stale cache if available
      if (cachedData != null) {
        try {
          final decodedData = json.decode(cachedData);
          if (decodedData is List) {
            final loadedPharmacies = decodedData
                .map((item) => Pharmacy.fromJson(item))
                .toList();
            // Update in-memory so UI can use it immediately
            _pharmacyCache.putIfAbsent(region, () => {})[town] =
                loadedPharmacies;
            if (lastFetchMillis != null) {
              _pharmacyLastFetchTimes.putIfAbsent(region, () => {})[town] =
                  DateTime.fromMillisecondsSinceEpoch(lastFetchMillis);
            }
            return loadedPharmacies;
          }
        } catch (_) {}
      }
      rethrow; // No cache and network failed
    }
  }

  Future<void> refreshData() async {
    // Refresh regions and towns
    _regionsAndTowns = await _service.fetchRegionsAndTowns();
    _regionsLastFetchTime = DateTime.now();
    await prefs.setString('regionsAndTowns', json.encode(_regionsAndTowns));
    await prefs.setInt(
      'regionsLastFetchTime',
      _regionsLastFetchTime!.millisecondsSinceEpoch,
    );

    // Clear all pharmacy caches (in-memory and persistent)
    _pharmacyCache.clear();
    _pharmacyLastFetchTimes.clear();
    // It's harder to clear all pharmacy_last_fetch_ keys from prefs without knowing them.
    // For simplicity, we might just let them expire naturally or clear specific ones if needed.
    // For now, clearing in-memory is sufficient for a "refresh" as subsequent calls will fetch new data.
  }

  /// Returns the last time data was fetched for a specific location.
  DateTime? getLastFetchTime(String region, String town) {
    // 1. Check in-memory
    if (_pharmacyLastFetchTimes[region]?[town] != null) {
      return _pharmacyLastFetchTimes[region]![town];
    }

    // 2. Check persistent storage
    final pharmacyLastFetchKey = 'pharmacy_last_fetch_${region}_$town';
    final lastFetchMillis = prefs.getInt(pharmacyLastFetchKey);
    if (lastFetchMillis != null) {
      return DateTime.fromMillisecondsSinceEpoch(lastFetchMillis);
    }
    return null;
  }

  bool _isCacheExpired(DateTime lastFetchTime) {
    // Reduced to 12 hours. If fetched at 6 PM, it expires at 6 AM next day.
    return DateTime.now().difference(lastFetchTime) > const Duration(hours: 12);
  }

  /// Forces a fetch from the network and updates the persistent cache.
  /// Used by the background worker to ensure data is fresh for the night.
  Future<void> updatePharmaciesInBackground(String region, String town) async {
    try {
      final pharmacies = await _service.fetchPharmacies(region, town);
      final now = DateTime.now();
      final cacheKey = 'pharmacies_${region}_$town';
      final pharmacyLastFetchKey = 'pharmacy_last_fetch_${region}_$town';

      await prefs.setString(
        cacheKey,
        json.encode(pharmacies.map((p) => p.toJson()).toList()),
      );
      await prefs.setInt(pharmacyLastFetchKey, now.millisecondsSinceEpoch);
      debugPrint('Background update successful for $town, $region');
    } catch (e) {
      debugPrint('Background update failed: $e');
      // We don't rethrow here to avoid crashing the background worker repeatedly
    }
  }

  // --- Favorite Cities Management ---

  List<String> getFavoriteCities() {
    return prefs.getStringList('favorite_cities') ?? [];
  }

  Future<void> toggleFavoriteCity(String region, String town) async {
    final favorites = getFavoriteCities();
    final key = "$region|$town";

    if (favorites.contains(key)) {
      favorites.remove(key);
    } else {
      favorites.add(key);
    }

    await prefs.setStringList('favorite_cities', favorites);
  }

  bool isFavoriteCity(String region, String town) {
    final favorites = getFavoriteCities();
    return favorites.contains("$region|$town");
  }
}
