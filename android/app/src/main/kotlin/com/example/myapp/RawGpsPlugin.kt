package com.example.myapp

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.GnssStatus
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Looper
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class RawGpsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private var locationManager: LocationManager? = null
    private var eventSink: EventChannel.EventSink? = null
    private var gnssCallback: GnssStatus.Callback? = null
    private var satelliteCount: Int = 0
    
    private val locationListener = object : LocationListener {
        override fun onLocationChanged(location: Location) {
            try {
                // Send raw GPS data to Flutter
                val data = hashMapOf(
                    "latitude" to location.latitude,
                    "longitude" to location.longitude,
                    "speed" to location.speed.toDouble(), // m/s - RAW speed from GPS
                    "accuracy" to location.accuracy.toDouble(),
                    "altitude" to location.altitude,
                    "bearing" to location.bearing.toDouble(),
                    "timestamp" to location.time,
                    "satelliteCount" to satelliteCount,
                    "provider" to (location.provider ?: "unknown")
                )
                eventSink?.success(data)
            } catch (e: Exception) {
                android.util.Log.e("RawGpsPlugin", "Error in onLocationChanged: ${e.message}")
            }
        }

        override fun onProviderEnabled(provider: String) {
            try {
                eventSink?.success(hashMapOf("event" to "provider_enabled", "provider" to provider))
            } catch (e: Exception) {
                android.util.Log.e("RawGpsPlugin", "Error in onProviderEnabled: ${e.message}")
            }
        }

        override fun onProviderDisabled(provider: String) {
            try {
                eventSink?.success(hashMapOf("event" to "provider_disabled", "provider" to provider))
            } catch (e: Exception) {
                android.util.Log.e("RawGpsPlugin", "Error in onProviderDisabled: ${e.message}")
            }
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        try {
            context = binding.applicationContext
            methodChannel = MethodChannel(binding.binaryMessenger, "raw_gps/method")
            methodChannel.setMethodCallHandler(this)
            
            eventChannel = EventChannel(binding.binaryMessenger, "raw_gps/location")
            eventChannel.setStreamHandler(this)
            
            locationManager = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            
            if (locationManager == null) {
                android.util.Log.e("RawGpsPlugin", "LocationManager is null!")
            }
        } catch (e: Exception) {
            android.util.Log.e("RawGpsPlugin", "Error in onAttachedToEngine: ${e.message}")
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        stopLocationUpdates()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startLocationUpdates" -> {
                startLocationUpdates(result)
            }
            "stopLocationUpdates" -> {
                stopLocationUpdates()
                result.success(null)
            }
            "getSatelliteCount" -> {
                result.success(satelliteCount)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun startLocationUpdates(result: MethodChannel.Result) {
        if (locationManager == null) {
            result.error("NO_LOCATION_MANAGER", "LocationManager not available", null)
            return
        }
        
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) 
            != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "Location permission not granted", null)
            return
        }

        try {
            // Request location updates with MAXIMUM FREQUENCY
            // minTimeMs = 0 -> No throttling, get updates as fast as GPS provides them
            // minDistanceM = 0f -> Update on every GPS tick, not just when moving
            locationManager?.requestLocationUpdates(
                LocationManager.GPS_PROVIDER,
                0L,        // minTimeMs = 0 (maximum frequency)
                0f,        // minDistanceM = 0 (no distance filter)
                locationListener,
                Looper.getMainLooper()
            )

            // Register GNSS Status listener to monitor satellite count and signal quality
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                try {
                    gnssCallback = object : GnssStatus.Callback() {
                        override fun onSatelliteStatusChanged(status: GnssStatus) {
                            try {
                                satelliteCount = status.satelliteCount
                                
                                // Optional: Send detailed satellite info to Flutter
                                val satelliteInfo = hashMapOf(
                                    "event" to "gnss_status",
                                    "satelliteCount" to satelliteCount,
                                    "usedInFix" to (0 until satelliteCount).count { status.usedInFix(it) }
                                )
                                eventSink?.success(satelliteInfo)
                            } catch (e: Exception) {
                                android.util.Log.e("RawGpsPlugin", "Error in onSatelliteStatusChanged: ${e.message}")
                            }
                        }

                        override fun onStarted() {
                            try {
                                eventSink?.success(hashMapOf("event" to "gnss_started"))
                            } catch (e: Exception) {
                                android.util.Log.e("RawGpsPlugin", "Error in onStarted: ${e.message}")
                            }
                        }

                        override fun onStopped() {
                            try {
                                eventSink?.success(hashMapOf("event" to "gnss_stopped"))
                            } catch (e: Exception) {
                                android.util.Log.e("RawGpsPlugin", "Error in onStopped: ${e.message}")
                            }
                        }
                    }
                    locationManager?.registerGnssStatusCallback(gnssCallback!!, null)
                } catch (e: Exception) {
                    android.util.Log.e("RawGpsPlugin", "Error registering GNSS callback: ${e.message}")
                    // Continue without GNSS status - not critical
                }
            }

            result.success(true)
        } catch (e: Exception) {
            result.error("START_FAILED", "Failed to start location updates: ${e.message}", null)
        }
    }

    private fun stopLocationUpdates() {
        try {
            locationManager?.removeUpdates(locationListener)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && gnssCallback != null) {
                locationManager?.unregisterGnssStatusCallback(gnssCallback!!)
            }
            satelliteCount = 0
        } catch (e: Exception) {
            android.util.Log.e("RawGpsPlugin", "Error stopping location updates: ${e.message}")
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
