package org.maphero.android.testapp.activity.options

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.MapView
import org.maphero.android.maps.OnMapReadyCallback
import org.maplibre.android.testapp.R

/**
 *  TestActivity demonstrating configuring MapView with XML
 */

class MapOptionsXmlActivity : AppCompatActivity(), OnMapReadyCallback {
    private lateinit var mapView: MapView
    private lateinit var mapHeroMap1: MapHeroMap

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_map_options_xml)
        mapView = findViewById(R.id.mapView)
        mapView.onCreate(savedInstanceState)
        mapView.getMapAsync(this)
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