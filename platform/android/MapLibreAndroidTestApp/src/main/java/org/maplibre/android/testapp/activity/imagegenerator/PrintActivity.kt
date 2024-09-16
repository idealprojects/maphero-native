package org.maplibre.android.testapp.activity.imagegenerator

import android.graphics.Bitmap
import android.os.Bundle
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import androidx.print.PrintHelper
import org.maplibre.android.maps.MapView
import org.maplibre.android.maps.MapHeroMap
import org.maplibre.android.testapp.R
import org.maplibre.android.testapp.styles.TestStyles

/**
 * Test activity showcasing using the Snapshot API to print a Map.
 */
class PrintActivity : AppCompatActivity(), MapHeroMap.SnapshotReadyCallback {
    private lateinit var mapView: MapView
    private lateinit var mapHeroMap: MapHeroMap
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_print)
        mapView = findViewById(R.id.mapView)
        mapView.onCreate(savedInstanceState)
        mapView.getMapAsync(this::initMap)
        val fab = findViewById<View>(R.id.fab)
        fab?.setOnClickListener { _: View? ->
            if (this::mapHeroMap.isInitialized && mapHeroMap.style != null) {
                mapHeroMap.snapshot(this@PrintActivity)
            }
        }
    }

    private fun initMap(mapHeroMap1: MapHeroMap) {
        this.mapHeroMap = mapHeroMap1
        mapHeroMap1.setStyle(TestStyles.getPredefinedStyleWithFallback("Streets"))
    }

    override fun onSnapshotReady(snapshot: Bitmap) {
        val photoPrinter = PrintHelper(this)
        photoPrinter.scaleMode = PrintHelper.SCALE_MODE_FIT
        photoPrinter.printBitmap("map.jpg - mapbox print job", snapshot)
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
