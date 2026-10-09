import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._internal();

  SettingsService._internal();

  final ValueNotifier<bool> gpsMultiBand = ValueNotifier<bool>(true);
  final ValueNotifier<bool> alwaysOnDisplay = ValueNotifier<bool>(true);
  final ValueNotifier<bool> oledMode = ValueNotifier<bool>(true);
  final ValueNotifier<bool> zoneAlerts = ValueNotifier<bool>(true);
  final ValueNotifier<bool> autoPauseEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<double> autoPauseThreshold = ValueNotifier<double>(2.5); // km/h
  final ValueNotifier<String> unitSystem = ValueNotifier<String>('Métrico'); // 'Métrico' o 'Imperial'
  final ValueNotifier<bool> stravaSync = ValueNotifier<bool>(false);
  final ValueNotifier<int> wheelCircumferenceMm = ValueNotifier<int>(2136); // 700x28C
  final ValueNotifier<String> hudScale = ValueNotifier<String>('Gigante'); // 'Compacto', 'Gigante', 'Total HUD'

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    gpsMultiBand.value = prefs.getBool('setting_gps_multiband') ?? true;
    alwaysOnDisplay.value = prefs.getBool('setting_always_on') ?? true;
    oledMode.value = prefs.getBool('setting_oled_mode') ?? true;
    zoneAlerts.value = prefs.getBool('setting_zone_alerts') ?? true;
    autoPauseEnabled.value = prefs.getBool('setting_autopause_enabled') ?? true;
    autoPauseThreshold.value = prefs.getDouble('setting_autopause_threshold') ?? 2.5;
    unitSystem.value = prefs.getString('setting_unit_system') ?? 'Métrico';
    stravaSync.value = prefs.getBool('setting_strava_sync') ?? false;
    wheelCircumferenceMm.value = prefs.getInt('setting_wheel_circumference') ?? 2136;
    hudScale.value = prefs.getString('setting_hud_scale') ?? 'Gigante';
  }

  Future<void> setGpsMultiBand(bool val) async {
    gpsMultiBand.value = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_gps_multiband', val);
  }

  Future<void> setAlwaysOnDisplay(bool val) async {
    alwaysOnDisplay.value = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_always_on', val);
  }

  Future<void> setOledMode(bool val) async {
    oledMode.value = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_oled_mode', val);
  }

  Future<void> setZoneAlerts(bool val) async {
    zoneAlerts.value = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_zone_alerts', val);
  }

  Future<void> setAutoPauseEnabled(bool val) async {
    autoPauseEnabled.value = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_autopause_enabled', val);
  }

  Future<void> setAutoPauseThreshold(double val) async {
    autoPauseThreshold.value = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('setting_autopause_threshold', val);
  }

  Future<void> setUnitSystem(String val) async {
    unitSystem.value = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('setting_unit_system', val);
  }

  Future<void> setStravaSync(bool val) async {
    stravaSync.value = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_strava_sync', val);
  }

  Future<void> setHudScale(String val) async {
    hudScale.value = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('setting_hud_scale', val);
  }
}
