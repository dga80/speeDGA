import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bike.dart';

class BikeService {
  static final BikeService instance = BikeService._internal();
  static const String _storageKey = 'speedga_bikes_list';
  static const String _activeBikeKey = 'speedga_active_bike_id';
  static const String _migratedDummyKey = 'speedga_cleared_dummy_bikes_v2';

  BikeService._internal();

  final ValueNotifier<List<Bike>> bikesNotifier = ValueNotifier<List<Bike>>([]);
  final ValueNotifier<Bike?> activeBikeNotifier = ValueNotifier<Bike?>(null);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Limpieza automática de las bicicletas de prueba/ficticias anteriores
    final alreadyCleared = prefs.getBool(_migratedDummyKey) ?? false;
    if (!alreadyCleared) {
      await prefs.remove(_storageKey);
      await prefs.remove(_activeBikeKey);
      await prefs.setBool(_migratedDummyKey, true);
    }

    final jsonStr = prefs.getString(_storageKey);
    List<Bike> loadedBikes = [];

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List list = jsonDecode(jsonStr);
        loadedBikes = list
            .map((m) => Bike.fromMap(Map<String, dynamic>.from(m)))
            // Descartar cualquier residuo de las bicicletas de ejemplo
            .where((b) => b.id != 'bike_road_1' && b.id != 'bike_gravel_2' && b.id != 'bike_mtb_3')
            .toList();
      } catch (e) {
        debugPrint('⚠️ Error decodificando bicicletas: $e');
        loadedBikes = [];
      }
    }

    // Si había dummies que se filtraron, guardar la lista limpia
    if (loadedBikes.isEmpty) {
      await prefs.remove(_storageKey);
      await prefs.remove(_activeBikeKey);
    } else {
      await _saveBikes(loadedBikes);
    }

    final activeId = prefs.getString(_activeBikeKey);
    Bike? active;
    if (loadedBikes.isNotEmpty) {
      try {
        active = loadedBikes.firstWhere(
          (b) => b.id == activeId,
          orElse: () => loadedBikes.firstWhere((b) => b.isDefault, orElse: () => loadedBikes.first),
        );
      } catch (_) {
        active = loadedBikes.first;
      }
    } else {
      active = null;
    }

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
    if (bikes.isEmpty) return;

    final updated = bikes.map((b) => b.copyWith(isDefault: b.id == bikeId)).toList();
    bikesNotifier.value = updated;
    try {
      activeBikeNotifier.value = updated.firstWhere((b) => b.id == bikeId);
    } catch (_) {
      activeBikeNotifier.value = updated.isNotEmpty ? updated.first : null;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeBikeKey, bikeId);
    await _saveBikes(updated);
  }

  Future<void> addBike(Bike newBike) async {
    final bikes = List<Bike>.from(bikesNotifier.value);
    final isFirst = bikes.isEmpty;
    final bikeToAdd = isFirst ? newBike.copyWith(isDefault: true) : newBike;

    bikes.add(bikeToAdd);
    bikesNotifier.value = bikes;

    if (isFirst || bikeToAdd.isDefault) {
      activeBikeNotifier.value = bikeToAdd;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeBikeKey, bikeToAdd.id);
    }

    await _saveBikes(bikes);
  }

  Future<void> deleteBike(String bikeId) async {
    final bikes = List<Bike>.from(bikesNotifier.value);
    bikes.removeWhere((b) => b.id == bikeId);
    bikesNotifier.value = bikes;

    final prefs = await SharedPreferences.getInstance();
    if (activeBikeNotifier.value?.id == bikeId) {
      if (bikes.isNotEmpty) {
        final newActive = bikes.firstWhere((b) => b.isDefault, orElse: () => bikes.first);
        activeBikeNotifier.value = newActive;
        await prefs.setString(_activeBikeKey, newActive.id);
      } else {
        activeBikeNotifier.value = null;
        await prefs.remove(_activeBikeKey);
      }
    }

    if (bikes.isEmpty) {
      await prefs.remove(_storageKey);
    } else {
      await _saveBikes(bikes);
    }
  }

  Future<void> clearAllBikes() async {
    bikesNotifier.value = [];
    activeBikeNotifier.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_activeBikeKey);
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
