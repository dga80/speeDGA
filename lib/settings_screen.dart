import 'package:flutter/material.dart';
import 'services/settings_service.dart';
import 'theme/speedga_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpeeDGATheme.darkCanvas,
      appBar: AppBar(
        backgroundColor: SpeeDGATheme.darkCanvas,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: SpeeDGATheme.neonLime,
                shape: BoxShape.circle,
                boxShadow: SpeeDGATheme.neonGlow(blur: 10, spread: 2),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'AJUSTES',
              style: TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.2,
                color: SpeeDGATheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Banner de contexto y estado de conectividad rápida
          _buildHeaderBanner(),
          const SizedBox(height: 24),

          // SECCIÓN 1: PANTALLA Y VISUALIZACIÓN
          _buildSectionHeader(
            icon: Icons.display_settings,
            title: 'PANTALLA & VISUALIZACIÓN',
            badge: 'HUD ACTIVO',
          ),
          const SizedBox(height: 10),
          _buildAlwaysOnTile(),
          _buildHudScaleTile(),
          _buildOledModeTile(),
          _buildZoneAlertsTile(),

          const SizedBox(height: 24),

          // SECCIÓN 2: SISTEMA Y TELEMETRÍA
          _buildSectionHeader(
            icon: Icons.memory,
            title: 'SISTEMA Y TELEMETRÍA',
            badge: 'METADATOS FIT',
          ),
          const SizedBox(height: 10),
          _buildSensorGpsTile(),
          _buildAutoPauseTile(),
          _buildUnitSystemTile(),
          _buildWheelCalibrationTile(),

          const SizedBox(height: 30),

          // Pie de Versión y Diagnóstico Cockpit
          _buildFooterVersion(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SpeeDGATheme.bentoCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONFIGURACIÓN & SENSORES',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Cockpit HUD Telemetría · Perfil Ciclista Pro',
                    style: TextStyle(fontSize: 12, color: SpeeDGATheme.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SpeeDGATheme.darkCardElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.settings, color: SpeeDGATheme.neonLime, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Chips rápidos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusPill('BLE 5.2 ONLINE', SpeeDGATheme.neonLime),
                const SizedBox(width: 8),
                _buildStatusPill('ANT+ ACTIVO', SpeeDGATheme.aeroCyan),
                const SizedBox(width: 8),
                _buildStatusPill('GPS 10Hz MULTIBANDA', SpeeDGATheme.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1217),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title, required String badge}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: SpeeDGATheme.neonLime, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        Text(
          badge,
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: SpeeDGATheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSensorGpsTile() {
    return ValueListenableBuilder<bool>(
      valueListenable: _settings.gpsMultiBand,
      builder: (context, enabled, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: SpeeDGATheme.bentoCardDecoration(),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SpeeDGATheme.darkCardElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.my_location, color: SpeeDGATheme.neonLime, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GPS Multibanda GNSS',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    SizedBox(height: 2),
                    Text('Precisión milimétrica < 1.5m',
                        style: TextStyle(fontSize: 11, color: SpeeDGATheme.neonLime, fontFamily: 'Courier')),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeColor: SpeeDGATheme.neonLime,
                activeTrackColor: SpeeDGATheme.neonLime.withOpacity(0.3),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.black26,
                onChanged: (val) => _settings.setGpsMultiBand(val),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSensorTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    bool isAction = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: SpeeDGATheme.bentoCardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SpeeDGATheme.darkCardElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: SpeeDGATheme.textSecondary)),
              ],
            ),
          ),
          if (isAction)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SpeeDGATheme.darkCardElevated,
                foregroundColor: SpeeDGATheme.neonLime,
                side: const BorderSide(color: SpeeDGATheme.neonLime, width: 0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Buscando sensores ANT+/BLE cercanos...')),
                );
              },
              child: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlwaysOnTile() {
    return ValueListenableBuilder<bool>(
      valueListenable: _settings.alwaysOnDisplay,
      builder: (context, enabled, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: SpeeDGATheme.bentoCardDecoration(),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SpeeDGATheme.darkCardElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.screen_lock_portrait, color: SpeeDGATheme.aeroCyan, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Always-On en Ruta',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    SizedBox(height: 2),
                    Text('Evita bloqueo de pantalla al pedalear (Wakelock)',
                        style: TextStyle(fontSize: 11, color: SpeeDGATheme.textSecondary)),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeColor: SpeeDGATheme.neonLime,
                onChanged: (val) => _settings.setAlwaysOnDisplay(val),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHudScaleTile() {
    return ValueListenableBuilder<String>(
      valueListenable: _settings.hudScale,
      builder: (context, currentScale, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: SpeeDGATheme.bentoCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.aspect_ratio, color: SpeeDGATheme.aeroCyan, size: 18),
                  SizedBox(width: 8),
                  Text('Escala del Velocímetro',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: ['Compacto', 'Gigante', 'Total HUD'].map((scale) {
                  final isSelected = scale == currentScale;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () => _settings.setHudScale(scale),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? SpeeDGATheme.neonLime : SpeeDGATheme.darkCardElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? SpeeDGATheme.neonLime : SpeeDGATheme.darkBorder,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              scale,
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black : SpeeDGATheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOledModeTile() {
    return ValueListenableBuilder<bool>(
      valueListenable: _settings.oledMode,
      builder: (context, enabled, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: SpeeDGATheme.bentoCardDecoration(),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SpeeDGATheme.darkCardElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.contrast, color: SpeeDGATheme.neonLime, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Modo OLED Puro',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    SizedBox(height: 2),
                    Text('Negro puro #000000 para máximo ahorro de batería',
                        style: TextStyle(fontSize: 11, color: SpeeDGATheme.textSecondary)),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeColor: SpeeDGATheme.neonLime,
                onChanged: (val) => _settings.setOledMode(val),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZoneAlertsTile() {
    return ValueListenableBuilder<bool>(
      valueListenable: _settings.zoneAlerts,
      builder: (context, enabled, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: SpeeDGATheme.bentoCardDecoration(),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SpeeDGATheme.darkCardElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active, color: SpeeDGATheme.warningAmber, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alertas Zonas & Audio',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    SizedBox(height: 2),
                    Text('Vibración y tono al cambiar de zona de velocidad',
                        style: TextStyle(fontSize: 11, color: SpeeDGATheme.textSecondary)),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeColor: SpeeDGATheme.neonLime,
                onChanged: (val) => _settings.setZoneAlerts(val),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAutoPauseTile() {
    return ValueListenableBuilder<bool>(
      valueListenable: _settings.autoPauseEnabled,
      builder: (context, enabled, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: SpeeDGATheme.bentoCardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: SpeeDGATheme.darkCardElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.pause_circle_outline, color: SpeeDGATheme.neonLime, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Auto-pausa Inteligente',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                        SizedBox(height: 2),
                        Text('Pausa cronómetro al detenerse en semáforos',
                            style: TextStyle(fontSize: 11, color: SpeeDGATheme.textSecondary)),
                      ],
                    ),
                  ),
                  Switch(
                    value: enabled,
                    activeColor: SpeeDGATheme.neonLime,
                    onChanged: (val) => _settings.setAutoPauseEnabled(val),
                  ),
                ],
              ),
              if (enabled) ...[
                const SizedBox(height: 12),
                ValueListenableBuilder<double>(
                  valueListenable: _settings.autoPauseThreshold,
                  builder: (context, threshold, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Umbral de parada:',
                            style: TextStyle(fontSize: 12, color: SpeeDGATheme.textSecondary)),
                        Text(
                          '< ${threshold.toStringAsFixed(1)} km/h',
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: SpeeDGATheme.neonLime,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnitSystemTile() {
    return ValueListenableBuilder<String>(
      valueListenable: _settings.unitSystem,
      builder: (context, currentUnit, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: SpeeDGATheme.bentoCardDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.straighten, color: SpeeDGATheme.aeroCyan, size: 20),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sistema de Unidades',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      SizedBox(height: 2),
                      Text('km/h, metros, grados °C',
                          style: TextStyle(fontSize: 11, color: SpeeDGATheme.textSecondary)),
                    ],
                  ),
                ],
              ),
              Row(
                children: ['Métrico', 'Imperial'].map((u) {
                  final isSelected = u == currentUnit;
                  return GestureDetector(
                    onTap: () => _settings.setUnitSystem(u),
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? SpeeDGATheme.neonLime : SpeeDGATheme.darkCardElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        u.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : SpeeDGATheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStravaSyncTile() {
    return ValueListenableBuilder<bool>(
      valueListenable: _settings.stravaSync,
      builder: (context, enabled, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: SpeeDGATheme.bentoCardDecoration(),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SpeeDGATheme.darkCardElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.share, color: SpeeDGATheme.warningAmber, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sincronización Strava / GPX',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    SizedBox(height: 2),
                    Text('Subida y exportación rápida de archivos GPX',
                        style: TextStyle(fontSize: 11, color: SpeeDGATheme.textSecondary)),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeColor: SpeeDGATheme.neonLime,
                onChanged: (val) => _settings.setStravaSync(val),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWheelCalibrationTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: SpeeDGATheme.bentoCardDecoration(),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.trip_origin, color: SpeeDGATheme.textSecondary, size: 20),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Circunferencia de Rueda',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  SizedBox(height: 2),
                  Text('700x28C · 2136 mm estándar',
                      style: TextStyle(fontSize: 11, color: SpeeDGATheme.textSecondary)),
                ],
              ),
            ],
          ),
          Icon(Icons.chevron_right, color: SpeeDGATheme.textMuted),
        ],
      ),
    );
  }

  Widget _buildFooterVersion() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: SpeeDGATheme.neonLime, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text(
              'speeDGA TELEMETRY OS',
              style: TextStyle(fontFamily: 'Courier', fontSize: 11, fontWeight: FontWeight.w900, color: SpeeDGATheme.neonLime),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'v2.4 Pro Edition · Algoritmos barométricos calibrados · Build 108.4',
          style: TextStyle(fontSize: 10, color: SpeeDGATheme.textMuted),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SpeeDGATheme.darkCard,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  side: const BorderSide(color: SpeeDGATheme.darkBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Diagnóstico: Sensores GPS 10Hz activos · Batería óptima · SQLite operativo'),
                      backgroundColor: SpeeDGATheme.darkCardElevated,
                    ),
                  );
                },
                icon: const Icon(Icons.bug_report, size: 16, color: SpeeDGATheme.neonLime),
                label: const Text(
                  'Diagnóstico Cockpit',
                  style: TextStyle(fontFamily: 'Courier', fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SpeeDGATheme.darkCard,
                  foregroundColor: SpeeDGATheme.alertOrange,
                  elevation: 0,
                  side: const BorderSide(color: SpeeDGATheme.darkBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ajustes restablecidos a valores recomendados'),
                      backgroundColor: SpeeDGATheme.darkCardElevated,
                    ),
                  );
                },
                icon: const Icon(Icons.refresh, size: 16, color: SpeeDGATheme.alertOrange),
                label: const Text(
                  'Restablecer',
                  style: TextStyle(fontFamily: 'Courier', fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
