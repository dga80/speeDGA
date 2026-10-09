import 'package:flutter/material.dart';
import 'models/bike.dart';
import 'services/bike_service.dart';
import 'theme/speedga_theme.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
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
              'GARAJE ACTIVO',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: SpeeDGATheme.neonLime, size: 26),
            tooltip: 'Añadir Bicicleta',
            onPressed: () => _showAddBikeDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ValueListenableBuilder<List<Bike>>(
        valueListenable: BikeService.instance.bikesNotifier,
        builder: (context, bikes, child) {
          final activeBike = BikeService.instance.activeBikeNotifier.value ??
              (bikes.isNotEmpty ? bikes.first : null);
          final otherBikes = bikes.where((b) => b.id != activeBike?.id).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              const Text(
                'Odometría satelital y telemetría por vehículo',
                style: TextStyle(
                  fontSize: 12,
                  color: SpeeDGATheme.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 16),

              if (activeBike != null) ...[
                _buildActiveBikeCard(activeBike),
                const SizedBox(height: 24),
              ],

              // Sección: Otras bicicletas registradas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'OTRAS BICICLETAS EN RESERVA',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: SpeeDGATheme.textSecondary,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    '${otherBikes.length} en garaje',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 11,
                      color: SpeeDGATheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (otherBikes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: SpeeDGATheme.bentoCardDecoration(),
                  child: const Center(
                    child: Text(
                      'No tienes más bicicletas registradas.',
                      style: TextStyle(color: SpeeDGATheme.textMuted, fontSize: 13),
                    ),
                  ),
                )
              else
                ...otherBikes.map((bike) => _buildSecondaryBikeCard(bike)),

              const SizedBox(height: 20),
              _buildMaintenanceBanner(),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  /// Tarjeta Bento Principal de la Bicicleta Activa
  Widget _buildActiveBikeCard(Bike bike) {
    return Container(
      decoration: SpeeDGATheme.bentoCardDecoration(
        backgroundColor: SpeeDGATheme.darkCard,
        borderColor: SpeeDGATheme.neonLime.withOpacity(0.35),
        glow: true,
        glowColor: SpeeDGATheme.neonLime,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado de uso predeterminado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: SpeeDGATheme.neonLime,
                      shape: BoxShape.circle,
                      boxShadow: SpeeDGATheme.neonGlow(blur: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'EN USO • PREDETERMINADA',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: SpeeDGATheme.neonLime,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SpeeDGATheme.darkCardElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SpeeDGATheme.darkBorder),
                ),
                child: Text(
                  bike.specs,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: SpeeDGATheme.aeroCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Título y modelo
          Text(
            bike.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: SpeeDGATheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            bike.brandModel,
            style: const TextStyle(
              fontSize: 13,
              color: SpeeDGATheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Odómetro y Métricas Acumuladas
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0F13),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SpeeDGATheme.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ODÓMETRO TOTAL',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: SpeeDGATheme.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: SpeeDGATheme.neonLime.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'CALIBRADO GPS',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: SpeeDGATheme.neonLime,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      bike.totalDistanceKm.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: SpeeDGATheme.textPrimary,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'KM',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: SpeeDGATheme.neonLime,
                      ),
                    ),
                  ],
                ),
                const Divider(color: SpeeDGATheme.darkBorder, height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.terrain, color: SpeeDGATheme.aeroCyan, size: 18),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DESNIVEL ACUM.',
                                  style: TextStyle(fontSize: 9, color: SpeeDGATheme.textMuted, fontFamily: 'Courier')),
                              Text('+${bike.totalElevationM.toStringAsFixed(0)} m',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: SpeeDGATheme.neonLime, size: 18),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ACTIVIDADES',
                                  style: TextStyle(fontSize: 9, color: SpeeDGATheme.textMuted, fontFamily: 'Courier')),
                              Text('${bike.totalSessions} salidas',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Vida Útil de Componentes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'VIDA ÚTIL DE COMPONENTES',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: SpeeDGATheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: SpeeDGATheme.neonLime, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Diagnóstico OK',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: SpeeDGATheme.neonLime,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Componente 1: Cadena
          _buildWearItem(
            title: 'Cadena Shimano Dura-Ace',
            pct: bike.chainWearPct,
            detail: 'Elongación 0.35 mm · ~1,120 km restantes',
            accentColor: SpeeDGATheme.neonLime,
            icon: Icons.link,
          ),
          const SizedBox(height: 8),

          // Componente 2: Cubiertas
          _buildWearItem(
            title: 'Cubiertas Continental GP5000',
            pct: bike.tireWearPct,
            detail: 'Banda de rodadura óptima · Presión rec: 4.8 BAR',
            accentColor: SpeeDGATheme.aeroCyan,
            icon: Icons.album_outlined,
          ),
          const SizedBox(height: 8),

          // Componente 3: Pastillas de Freno
          _buildWearItem(
            title: 'Pastillas Freno SwissStop',
            pct: bike.brakeWearPct,
            detail: 'Compuesto orgánico con 85% de grosor',
            accentColor: SpeeDGATheme.neonLime,
            icon: Icons.adjust,
          ),
        ],
      ),
    );
  }

  Widget _buildWearItem({
    required String title,
    required double pct,
    required String detail,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SpeeDGATheme.darkCardElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SpeeDGATheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: SpeeDGATheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100.0,
              backgroundColor: const Color(0xFF13181F),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: const TextStyle(fontSize: 10, color: SpeeDGATheme.textMuted, fontFamily: 'Courier'),
          ),
        ],
      ),
    );
  }

  /// Tarjeta de Bicicleta Secundaria en Reserva
  Widget _buildSecondaryBikeCard(Bike bike) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: SpeeDGATheme.bentoCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bike.name,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    bike.brandModel,
                    style: const TextStyle(fontSize: 12, color: SpeeDGATheme.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SpeeDGATheme.darkCardElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SpeeDGATheme.darkBorder),
                ),
                child: Text(
                  bike.type.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: SpeeDGATheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ODÓMETRO',
                        style: TextStyle(fontSize: 9, color: SpeeDGATheme.textMuted, fontFamily: 'Courier')),
                    Text('${bike.totalDistanceKm.toStringAsFixed(1)} KM',
                        style: const TextStyle(
                            fontFamily: 'Courier', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SALIDAS',
                        style: TextStyle(fontSize: 9, color: SpeeDGATheme.textMuted, fontFamily: 'Courier')),
                    Text('${bike.totalSessions} rutas',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: SpeeDGATheme.neonLime.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () async {
                await BikeService.instance.setActiveBike(bike.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🚲 Activada "${bike.name}" como bicicleta principal'),
                      backgroundColor: SpeeDGATheme.darkCard,
                    ),
                  );
                }
              },
              child: const Text(
                'SELECCIONAR COMO ACTIVA',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: SpeeDGATheme.neonLime,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Banner de Mantenimiento Preventivo
  Widget _buildMaintenanceBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF17130F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SpeeDGATheme.warningAmber.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SpeeDGATheme.warningAmber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.build_circle_outlined, color: SpeeDGATheme.warningAmber, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mantenimiento Preventivo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
                SizedBox(height: 2),
                Text(
                  'Purgado de frenos recomendado en 150 km',
                  style: TextStyle(fontSize: 11, color: SpeeDGATheme.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Ver Taller', style: TextStyle(color: SpeeDGATheme.warningAmber, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showAddBikeDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final specsCtrl = TextEditingController();
    String selectedType = 'Carretera';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: SpeeDGATheme.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: SpeeDGATheme.darkBorder),
          ),
          title: const Text(
            'Añadir Nueva Bicicleta',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nombre o Alias',
                    labelStyle: TextStyle(color: SpeeDGATheme.textSecondary),
                    hintText: 'Ej. Bici Enduro, Gravel Canyon',
                    hintStyle: TextStyle(color: SpeeDGATheme.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: modelCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Marca y Modelo',
                    labelStyle: TextStyle(color: SpeeDGATheme.textSecondary),
                    hintText: 'Ej. Trek Madone SLR',
                    hintStyle: TextStyle(color: SpeeDGATheme.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: specsCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Detalles / Peso / Transmisión',
                    labelStyle: TextStyle(color: SpeeDGATheme.textSecondary),
                    hintText: 'Ej. 7.2 KG • 50-34T',
                    hintStyle: TextStyle(color: SpeeDGATheme.textMuted),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: SpeeDGATheme.darkCardElevated,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Disciplina',
                    labelStyle: TextStyle(color: SpeeDGATheme.textSecondary),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Carretera', child: Text('Carretera')),
                    DropdownMenuItem(value: 'Gravel', child: Text('Gravel')),
                    DropdownMenuItem(value: 'MTB', child: Text('MTB')),
                    DropdownMenuItem(value: 'Urbana', child: Text('Urbana')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: SpeeDGATheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SpeeDGATheme.neonLime,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  final newBike = Bike(
                    id: 'bike_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    brandModel: modelCtrl.text.trim().isEmpty ? 'Bicicleta Pro' : modelCtrl.text.trim(),
                    specs: specsCtrl.text.trim().isEmpty ? 'Personalizada' : specsCtrl.text.trim(),
                    type: selectedType,
                    totalDistanceKm: 0.0,
                    totalElevationM: 0.0,
                    totalSessions: 0,
                    chainWearPct: 100.0,
                    tireWearPct: 100.0,
                    brakeWearPct: 100.0,
                  );
                  await BikeService.instance.addBike(newBike);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
