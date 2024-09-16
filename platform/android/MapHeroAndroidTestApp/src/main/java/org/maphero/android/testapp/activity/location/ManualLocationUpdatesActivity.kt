package org.maphero.android.testapp.activity.location

import android.annotation.SuppressLint
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.floatingactionbutton.FloatingActionButton
import org.maphero.android.geometry.LatLngBounds
import org.maphero.android.location.LocationComponent
import org.maphero.android.location.LocationComponentActivationOptions
import org.maphero.android.location.engine.LocationEngine
import org.maphero.android.location.engine.LocationEngineDefault
import org.maphero.android.location.engine.LocationEngineRequest
import org.maphero.android.location.modes.RenderMode
import org.maphero.android.location.permissions.PermissionsListener
import org.maphero.android.location.permissions.PermissionsManager
import org.maphero.android.maps.MapView
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.OnMapReadyCallback
import org.maphero.android.maps.Style
import org.maphero.android.testapp.R
import org.maphero.android.testapp.styles.TestStyles

class ManualLocationUpdatesActivity : AppCompatActivity(), OnMapReadyCallback {
    private lateinit var mapView: MapView
    private var locationComponent: LocationComponent? = null
    private var locationEngine: LocationEngine? = null
    private var permissionsManager: PermissionsManager? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_location_manual_update)
        locationEngine = LocationEngineDefault.getDefaultLocationEngine(mapView.context)
        val fabManualUpdate = findViewById<FloatingActionButton>(R.id.fabManualLocationChange)
        fabManualUpdate.setOnClickListener { v: View? ->
            if (locationComponent != null && locationComponent!!.locationEngine == null) {
                locationComponent!!.forceLocationUpdate(
                    Utils.getRandomLocation(LatLngBounds.from(60.0, 25.0, 40.0, -5.0))
                )
            }
        }
        fabManualUpdate.isEnabled = false
        val fabToggle = findViewById<FloatingActionButton>(R.id.fabToggleManualLocation)
        fabToggle.setOnClickListener { v: View? ->
            if (locationComponent != null) {
                locationComponent!!.locationEngine =
                    if (locationComponent!!.locationEngine == null) locationEngine else null
                if (locationComponent!!.locationEngine == null) {
                    fabToggle.setImageResource(R.drawable.ic_layers_clear)
                    fabManualUpdate.isEnabled = true
                    fabManualUpdate.alpha = 1f
                    Toast.makeText(
                        this@ManualLocationUpdatesActivity.applicationContext,
                        "LocationEngine disabled, use manual updates",
                        Toast.LENGTH_SHORT
                    ).show()
                } else {
                    fabToggle.setImageResource(R.drawable.ic_layers)
                    fabManualUpdate.isEnabled = false
                    fabManualUpdate.alpha = 0.5f
                    Toast.makeText(
                        this@ManualLocationUpdatesActivity.applicationContext,
                        "LocationEngine enabled",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
        }
        mapView = findViewById(R.id.mapView)
        mapView.onCreate(savedInstanceState)
        if (PermissionsManager.areLocationPermissionsGranted(this)) {
            mapView.getMapAsync(this)
        } else {
            permissionsManager = PermissionsManager(object : PermissionsListener {
                override fun onExplanationNeeded(permissionsToExplain: List<String>) {
                    Toast.makeText(
                        this@ManualLocationUpdatesActivity.applicationContext,
                        "You need to accept location permissions.",
                        Toast.LENGTH_SHORT
                    ).show()
                }

                override fun onPermissionResult(granted: Boolean) {
                    if (granted) {
                        mapView.getMapAsync(this@ManualLocationUpdatesActivity)
                    } else {
                        finish()
                    }
                }
            })
            permissionsManager!!.requestLocationPermissions(this)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        permissionsManager!!.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    @SuppressLint("MissingPermission")
    override fun onMapReady(mapHeroMap: MapHeroMap) {
        mapHeroMap.setStyle(
            Style.Builder().fromUri(TestStyles.getPredefinedStyleWithFallback("Streets"))
        ) { style: Style? ->
            locationComponent = mapHeroMap.locationComponent
            locationComponent!!.activateLocationComponent(
                LocationComponentActivationOptions
                    .builder(this, style!!)
                    .locationEngine(locationEngine)
                    .locationEngineRequest(
                        LocationEngineRequest.Builder(500)
                            .setFastestInterval(500)
                            .setPriority(LocationEngineRequest.PRIORITY_HIGH_ACCURACY).build()
                    )
                    .build()
            )
            locationComponent!!.isLocationComponentEnabled = true
            locationComponent!!.renderMode = RenderMode.COMPASS
        }
    }

    override fun onStart() {
        super.onStart()
        mapView.onStart()
    }

    override fun onResume() {
        super.onResume()
        mapView.onResume()
    }

    override fun onPause() {
        super.onPause()
        mapView.onPause()
    }

    override fun onStop() {
        super.onStop()
        mapView.onStop()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        mapView.onSaveInstanceState(outState)
    }

    override fun onDestroy() {
        super.onDestroy()
        mapView.onDestroy()
    }

    override fun onLowMemory() {
        super.onLowMemory()
        mapView.onLowMemory()
    }
}
