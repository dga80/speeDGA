import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bike.dart';

class BikeService {
  static final BikeService instance = BikeService._internal();
  static const String _storageKey = 'speedga_bikes_list';
  static const String _activeBikeKey = 'speedga_active_bike_id';

  BikeService._internal();

  final ValueNotifier<List<Bike>> bikesNotifier = ValueNotifier<List<Bike>>([]);
  final ValueNotifier<Bike?> activeBikeNotifier = ValueNotifier<Bike?>(null);

  final List<Bike> _defaultBikes = [
    Bike(
      id: 'bike_road_1',
      name: 'Carretera Aero',
      brandModel: 'Canyon Ultimate CFR • Di2 12S',
      specs: '6.85 KG • 52-36T',
      type: 'Carretera',
      totalDistanceKm: 1428.5,
      totalElevationM: 12450.0,
      totalSessions: 64,
      chainWearPct: 78.0,
      tireWearPct: 62.0,
      brakeWearPct: 85.0,
      isDefault: true,
    ),
    Bike(
      id: 'bike_gravel_2',
      name: 'Bici Gravel (Canyon)',
      brandModel: 'Canyon Grizl CF • GRX 810',
      specs: '8.90 KG • 1x11 40T',
      type: 'Gravel',
      totalDistanceKm: 842.0,
      totalElevationM: 7450.0,
      totalSessions: 28,
      chainWearPct: 65.0,
      tireWearPct: 45.0,
      brakeWearPct: 70.0,
      isDefault: false,
    ),
    Bike(
      id: 'bike_mtb_3',
      name: 'MTB Doble',
      brandModel: 'Specialized Epic EVO • Sram 29"',
      specs: '10.8 KG • Fox 120mm',
      type: 'MTB',
      totalDistanceKm: 415.2,
      totalElevationM: 5800.0,
      totalSessions: 16,
      chainWearPct: 52.0,
      tireWearPct: 35.0,
      brakeWearPct: 90.0,
      isDefault: false,
    ),
  ];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    List<Bike> loadedBikes = [];

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List list = jsonDecode(jsonStr);
        loadedBikes = list.map((m) => Bike.fromMap(Map<String, dynamic>.from(m))).toList();
      } catch (e) {
        debugPrint('⚠️ Error decodificando bicicletas: $e');
        loadedBikes = List.from(_defaultBikes);
      }
    } else {
      loadedBikes = List.from(_defaultBikes);
      await _saveBikes(loadedBikes);
    }

    final activeId = prefs.getString(_activeBikeKey);
    Bike? active = loadedBikes.firstWhere(
      (b) => b.id == activeId,
      orElse: () => loadedBikes.firstWhere((b) => b.isDefault, orElse: () => loadedBikes.first),
    );

    bikesNotifier.value = loadedBikes;
    activeBikeNotifier.value = active;
  }

  Future<void> _saveBikes(List<Bike> bikes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(bikes.map((b) => b.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> setActiveBike(String bikeId) async {
    final bikes = List<Bike>.from(bikesNotifier.value);
    final updated = bikes.map((b) => b.copyWith(isDefault: b.id == bikeId)).toList();
    bikesNotifier.value = updated;
    activeBikeNotifier.value = updated.firstWhere((b) => b.id == bikeId, orElse: () => updated.first);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeBikeKey, bikeId);
    await _saveBikes(updated);
  }

  Future<void> addBike(Bike newBike) async {
    final bikes = List<Bike>.from(bikesNotifier.value);
    bikes.add(newBike);
    bikesNotifier.value = bikes;
    await _saveBikes(bikes);
  }

  Future<void> recordTripForActiveBike({required double distanceKm, required double elevationM}) async {
    final active = activeBikeNotifier.value;
    if (active == null) return;

    final bikes = List<Bike>.from(bikesNotifier.value);
    final index = bikes.indexWhere((b) => b.id == active.id);
    if (index != -1) {
      final current = bikes[index];
      // Cada ~3500 km la cadena se gasta un 100%
      final addedChainWear = (distanceKm / 3500.0) * 100.0;
      final newChainWear = (current.chainWearPct - addedChainWear).clamp(0.0, 100.0);

      final updatedBike = current.copyWith(
        totalDistanceKm: current.totalDistanceKm + distanceKm,
        totalElevationM: current.totalElevationM + elevationM,
        totalSessions: current.totalSessions + 1,
        chainWearPct: newChainWear,
      );

      bikes[index] = updatedBike;
      bikesNotifier.value = bikes;
      activeBikeNotifier.value = updatedBike;
      await _saveBikes(bikes);
    }
  }
}
