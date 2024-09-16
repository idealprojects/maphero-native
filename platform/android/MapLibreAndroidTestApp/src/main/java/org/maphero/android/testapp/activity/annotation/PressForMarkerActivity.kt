package org.maphero.android.testapp.activity.annotation

import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import org.maphero.android.annotations.MarkerOptions
import org.maphero.android.geometry.LatLng
import org.maphero.android.maps.MapView
import org.maphero.android.maps.MapHeroMap
import org.maplibre.android.testapp.R
import org.maphero.android.testapp.styles.TestStyles
import java.text.DecimalFormat
import java.util.ArrayList

/**
 * Test activity showcasing to add a Marker on click.
 *
 *
 * Shows how to use a OnMapClickListener and a OnMapLongClickListener
 *
 */
class PressForMarkerActivity : AppCompatActivity() {
    private lateinit var mapView: MapView
    private lateinit var mapHeroMap: MapHeroMap
    private var markerList: ArrayList<MarkerOptions>? = ArrayList()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_press_for_marker)
        mapView = findViewById<View>(R.id.mapView) as MapView
        mapView.onCreate(savedInstanceState)
        mapView.getMapAsync { map: MapHeroMap? ->
            if (map != null) {
                mapHeroMap = map
            }
            resetMap()
            mapHeroMap.addOnMapLongClickListener { point: LatLng ->
                addMarker(point)
                false
            }
            mapHeroMap.addOnMapClickListener { point: LatLng ->
                addMarker(point)
                false
            }
            mapHeroMap.setStyle(TestStyles.getPredefinedStyleWithFallback("Streets"))
            if (savedInstanceState != null) {
                markerList = savedInstanceState.getParcelableArrayList(STATE_MARKER_LIST, MarkerOptions::class.java)
                if (markerList != null) {
                    mapHeroMap.addMarkers(markerList!!)
                }
            }
        }
    }

    private fun addMarker(point: LatLng) {
        val pixel = mapHeroMap.projection.toScreenLocation(point)
        val title = (
            LAT_LON_FORMATTER.format(point.latitude) + ", " +
                LAT_LON_FORMATTER.format(point.longitude)
            )
        val snippet = "X = " + pixel.x.toInt() + ", Y = " + pixel.y.toInt()
        val marker = MarkerOptions()
            .position(point)
            .title(title)
            .snippet(snippet)
        markerList!!.add(marker)
        mapHeroMap.addMarker(marker)
    }

    private fun resetMap() {
        if (this::mapHeroMap.isInitialized) {
            markerList?.clear()
            mapHeroMap.removeAnnotations()
        }
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.menu_press_for_marker, menu)
        return true
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        mapView.onSaveInstanceState(outState)
        outState.putParcelableArrayList(STATE_MARKER_LIST, markerList)
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

    override fun onDestroy() {
        super.onDestroy()
        mapView.onDestroy()
    }

    override fun onLowMemory() {
        super.onLowMemory()
        mapView.onLowMemory()
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.menuItemReset -> {
                resetMap()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    companion object {
        private val LAT_LON_FORMATTER = DecimalFormat("#.#####")
        private const val STATE_MARKER_LIST = "markerList"
    }
}
