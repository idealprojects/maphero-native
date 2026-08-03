package org.maphero.android.testapp.activity.style

import android.os.Bundle
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import org.maphero.android.maps.MapView
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.Style
import org.maphero.android.testapp.R
import org.maphero.android.testapp.styles.TestStyles

/**
 * Test activity used for instrumentation tests of fill extrusion.
 */
class FillExtrusionStyleTestActivity : AppCompatActivity() {
    lateinit var mapView: MapView
    lateinit var maplibreMap: MapHeroMap
        private set

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_extrusion_test)

        // Initialize map as normal
        mapView = findViewById<View>(R.id.mapView) as MapView
        mapView.onCreate(savedInstanceState)
        mapView.getMapAsync { maplibreMap: MapHeroMap ->
            maplibreMap.setStyle(
                Style.Builder().fromUri(TestStyles.getPredefinedStyleWithFallback("Streets"))
            ) { style: Style? -> this@FillExtrusionStyleTestActivity.maplibreMap = maplibreMap }
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
