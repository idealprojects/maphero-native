package org.maphero.android.testapp.activity.location

import android.annotation.SuppressLint
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.floatingactionbutton.FloatingActionButton
import org.maphero.android.location.LocationComponentActivationOptions
import org.maphero.android.location.modes.RenderMode
import org.maphero.android.location.permissions.PermissionsListener
import org.maphero.android.location.permissions.PermissionsManager
import org.maphero.android.maps.MapView
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.OnMapReadyCallback
import org.maphero.android.maps.Style
import org.maphero.android.testapp.R

class LocationMapChangeActivity : AppCompatActivity(), OnMapReadyCallback {
    private lateinit var mapView: MapView
    private lateinit var mapHeroMap1: MapHeroMap
    private var permissionsManager: PermissionsManager? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_location_layer_map_change)
        mapView = findViewById(R.id.mapView)
        val stylesFab = findViewById<FloatingActionButton>(R.id.fabStyles)
        stylesFab.setOnClickListener { v: View? ->
            if (this::mapHeroMap1.isInitialized) {
                mapHeroMap1.setStyle(Style.Builder().fromUri(Utils.nextStyle()))
            }
        }
        mapView.onCreate(savedInstanceState)
        if (PermissionsManager.areLocationPermissionsGranted(this)) {
            mapView.getMapAsync(this)
        } else {
            permissionsManager = PermissionsManager(object : PermissionsListener {
                override fun onExplanationNeeded(permissionsToExplain: List<String>) {
                    Toast.makeText(
                        this@LocationMapChangeActivity,
                        "You need to accept location permissions.",
                        Toast.LENGTH_SHORT
                    ).show()
                }

                override fun onPermissionResult(granted: Boolean) {
                    if (granted) {
                        mapView.getMapAsync(this@LocationMapChangeActivity)
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

    override fun onMapReady(mapHeroMap: MapHeroMap) {
        this.mapHeroMap1 = mapHeroMap
        mapHeroMap.setStyle(
            Style.Builder().fromUri(Utils.nextStyle())
        ) { style: Style -> activateLocationComponent(style) }
    }

    @SuppressLint("MissingPermission")
    private fun activateLocationComponent(style: Style) {
        val locationComponent = mapHeroMap1.locationComponent
        locationComponent.activateLocationComponent(
            LocationComponentActivationOptions
                .builder(this, style)
                .useDefaultLocationEngine(true)
                .build()
        )
        locationComponent.isLocationComponentEnabled = true
        locationComponent.renderMode = RenderMode.COMPASS
        locationComponent.addOnLocationClickListener {
            Toast.makeText(
                this,
                "Location clicked",
                Toast.LENGTH_SHORT
            ).show()
        }
        locationComponent.addOnLocationLongClickListener {
            Toast.makeText(
                this,
                "Location long clicked",
                Toast.LENGTH_SHORT
            ).show()
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
