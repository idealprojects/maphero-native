package org.maphero.android.testapp.activity.camera

import android.graphics.Point
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import org.maphero.android.camera.CameraUpdateFactory
import org.maphero.android.maps.MapView
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.Style
import org.maphero.android.testapp.R
import org.maphero.android.testapp.styles.TestStyles

/**
 * Test activity showcasing the zoom Camera API.
 *
 * This includes zoomIn, zoomOut, zoomTo, zoomBy (center and custom focal point).
 */
class ManualZoomActivity : AppCompatActivity() {
    private lateinit var mapHeroMap: MapHeroMap
    private lateinit var mapView: MapView
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_manual_zoom)
        mapView = findViewById<View>(R.id.mapView) as MapView
        mapView.onCreate(savedInstanceState)
        mapView.getMapAsync { mapHeroMap1: MapHeroMap ->
            this@ManualZoomActivity.mapHeroMap = mapHeroMap1
            mapHeroMap1.setStyle(
                Style.Builder().fromUri(TestStyles.getPredefinedStyleWithFallback("Satellite Hybrid"))
            )
            val uiSettings = this@ManualZoomActivity.mapHeroMap.uiSettings
            uiSettings.setAllGesturesEnabled(false)
        }
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.menu_zoom, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_zoom_in -> {
                mapHeroMap.animateCamera(CameraUpdateFactory.zoomIn())
                true
            }
            R.id.action_zoom_out -> {
                mapHeroMap.animateCamera(CameraUpdateFactory.zoomOut())
                true
            }
            R.id.action_zoom_by -> {
                mapHeroMap.animateCamera(CameraUpdateFactory.zoomBy(2.0))
                true
            }
            R.id.action_zoom_to -> {
                mapHeroMap.animateCamera(CameraUpdateFactory.zoomTo(2.0))
                true
            }
            R.id.action_zoom_to_point -> {
                val view = window.decorView
                mapHeroMap.animateCamera(
                    CameraUpdateFactory.zoomBy(
                        1.0,
                        Point(view.measuredWidth / 4, view.measuredHeight / 4)
                    )
                )
                true
            }
            else -> super.onOptionsItemSelected(item)
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
