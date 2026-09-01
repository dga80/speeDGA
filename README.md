# speeDGA - Ciclocomputador GPS para Bicicleta

**speeDGA** es una aplicación de telemetría de alta precisión diseñada para ciclismo de carretera, gravel y MTB. Funciona tanto como aplicación nativa Android (APK) como Progressive Web App (PWA) instalable en el navegador.

---

## 🚴 Características Principales

* **Base de Datos 100% Local (SQLite):**
  * Toda la información se almacena en el propio dispositivo (SQLite en Android y almacenamiento persistente en Web).
  * **Cero desconexiones:** Nunca se apaga ni se congela por inactividad.
  * **100% Offline:** Registra tus salidas en mitad de la montaña o pistas sin cobertura de datos móviles.
  * **Esquema versionado:** Definido en [`assets/database/schema.sql`](assets/database/schema.sql).

* **Compatibilidad con el Ecosistema Ciclista (GPX / Strava):**
  * Exporta cualquier salida a formato estándar **GPX 1.1** con trackpoints, marcas de tiempo, altitud y velocidad.
  * Botón directo para compartir tus rutas con **Strava, Wikiloc, Garmin Connect, Google Drive o WhatsApp**.

* **Telemetría Avanzada para Manillar:**
  * **Velocímetro de alta visibilidad:** Tipografía gigante en verde flúor con excelente legibilidad bajo sol directo.
  * **Desnivel Positivo Acumulado (+D):** Cálculo de metros ascendidos con filtro de histéresis para eliminar fluctuaciones del sensor.
  * **Pausa Automática (Auto-Pause):** Detiene el cronómetro en paradas y semáforos para mantener la precisión de la velocidad media.
  * **Velocidad Media Dinámica:** Calculada sobre el tiempo efectivo en pedaleo.
  * **Datos Meteorológicos Ciclistas:** Muestra temperatura, icono del tiempo, y velocidad y dirección del viento (km/h y rumbo cardinal) mediante la API de Open-Meteo.
  * **Soporte Adaptable:** Interfaz optimizada tanto para posición **vertical** como **horizontal (apaisado)** en el manillar.

* **Historial y Odómetro de la Bicicleta:**
  * Odómetro acumulado de por vida (kilómetros totales, desnivel total subido, salidas realizadas y velocidad punta).
  * Visualización de rutas en mapa interactivo con OpenStreetMap con marcadores de salida y meta.

---

## 📲 Instalación y Uso

### Opción 1: App Web Instalable (PWA)
1. Entra desde tu navegador móvil (Chrome en Android / Safari en iOS) a:
   **[https://speedga80.netlify.app](https://speedga80.netlify.app)**
2. Abre el menú del navegador (tres puntos) y selecciona **"Instalar aplicación"** o **"Añadir a pantalla de inicio"**.
3. Se abrirá a pantalla completa como una app nativa con soporte para tu GPS y almacenamiento local.

### Opción 2: Descargar APK Nativa para Android
Cada cambio en la rama `main` compila automáticamente la última versión del `.apk` mediante GitHub Actions:
👉 **[Descargar último speeDGA.apk en Releases](https://github.com/dga80/speeDGA/releases)**

---

## 🛠️ Estructura del Proyecto

```
speeDGA/
├── assets/database/
│   └── schema.sql              # Esquema canónico de la base de datos local SQLite
├── lib/
│   ├── models/
│   │   └── trip.dart           # Modelos fuertemente tipados (Trip, TripPoint)
│   ├── services/
│   │   ├── database_helper.dart # Gestor local SQLite y Web storage
│   │   ├── gpx_service.dart    # Generador y exportador GPX 1.1 (Strava)
│   │   └── weather_service.dart# Servicio de clima ciclista y viento
│   ├── history_screen.dart     # Odómetro global y listado de rutas
│   ├── map_screen.dart         # Visualizador de mapa interactivo
│   ├── raw_gps_service.dart    # Acceso GPS híbrido (Android GNSS / Web HTML5)
│   └── main.dart               # Pantalla principal del ciclocomputador
├── .github/workflows/
│   └── build_apk.yml           # CI/CD: Compilación automática del APK
└── web/
    └── manifest.json           # Configuración PWA para móvil y manillar
```

---

## 📄 Licencia

Uso privado y personal. Desarrollado con Flutter.
