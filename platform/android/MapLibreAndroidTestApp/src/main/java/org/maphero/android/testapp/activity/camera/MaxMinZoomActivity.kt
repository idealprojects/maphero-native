package org.maphero.android.testapp.activity.camera

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import org.maphero.android.maps.MapView
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.MapHeroMap.OnMapClickListener
import org.maphero.android.maps.OnMapReadyCallback
import org.maphero.android.maps.Style
import org.maplibre.android.testapp.R
import org.maphero.android.testapp.styles.TestStyles
import timber.log.Timber

/** Test activity showcasing using maximum and minimum zoom levels to restrict camera movement. */
class MaxMinZoomActivity : AppCompatActivity(), OnMapReadyCallback {
    private lateinit var mapView: MapView
    private lateinit var mapHeroMap1: MapHeroMap
    private val clickListener = OnMapClickListener {
        if (this::mapHeroMap1.isInitialized) {
            mapHeroMap1.setStyle(Style.Builder().fromUri(TestStyles.getPredefinedStyleWithFallback("Outdoor")))
        }
        true
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_maxmin_zoom)
        mapView = findViewById(R.id.mapView)
        mapView.onCreate(savedInstanceState)
        mapView.getMapAsync(this)
        mapView.addOnDidFinishLoadingStyleListener { Timber.d("Style Loaded") }
    }

    override fun onMapReady(mapHeroMap: MapHeroMap) {
        mapHeroMap1 = mapHeroMap
        mapHeroMap1.setStyle(TestStyles.getPredefinedStyleWithFallback("Streets"))
        mapHeroMap1.setMinZoomPreference(3.0)
        mapHeroMap1.setMaxZoomPreference(5.0)
        mapHeroMap1.addOnMapClickListener(clickListener)
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
        if (this::mapHeroMap1.isInitialized) {
            mapHeroMap1.removeOnMapClickListener(clickListener)
        }
        mapView.onDestroy()
    }

    override fun onLowMemory() {
        super.onLowMemory()
        mapView.onLowMemory()
    }
}
