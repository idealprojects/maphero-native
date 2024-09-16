package org.maphero.android.testapp.activity.options

import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import androidx.appcompat.app.AppCompatActivity
import org.maphero.android.camera.CameraPosition
import org.maphero.android.geometry.LatLng
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.MapHeroMapOptions
import org.maphero.android.maps.MapView
import org.maphero.android.maps.OnMapReadyCallback
import org.maplibre.android.testapp.R

/**
 *  TestActivity demonstrating configuring MapView with MapOptions
 */
class MapOptionsRuntimeActivity : AppCompatActivity(), OnMapReadyCallback {

    private lateinit var mapHeroMap1: MapHeroMap
    private lateinit var mapView: MapView
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_map_options_runtime)

        // Create map configuration
        val mapHeroMapOptions = MapHeroMapOptions.createFromAttributes(this)
        mapHeroMapOptions.apply {
            apiBaseUri("https://api.maplibre.org")
            camera(
                CameraPosition.Builder()
                    .bearing(0.0)
                    .target(LatLng(42.31230486601532, 64.63967338936439))
                    .zoom(3.9)
                    .tilt(0.0)
                    .build()
            )
            maxPitchPreference(90.0)
            minPitchPreference(0.0)
            maxZoomPreference(26.0)
            minZoomPreference(2.0)
            localIdeographFontFamily("Droid Sans")
            zoomGesturesEnabled(true)
            compassEnabled(true)
            compassFadesWhenFacingNorth(true)
            scrollGesturesEnabled(true)
            rotateGesturesEnabled(true)
            tiltGesturesEnabled(true)
        }

        // Create map programmatically, add to view hierarchy
        mapView = MapView(this, mapHeroMapOptions)
        mapView.getMapAsync(this)
        mapView.onCreate(savedInstanceState)
        (findViewById<View>(R.id.container) as ViewGroup).addView(mapView)
    }

    override fun onMapReady(mapHeroMap: MapHeroMap) {
        this.mapHeroMap1 = mapHeroMap
        this.mapHeroMap1.setStyle("https://demotiles.maplibre.org/style.json")
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