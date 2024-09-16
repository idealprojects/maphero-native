package org.maphero.android.testapp.activity.infowindow

import android.graphics.Color
import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.res.ResourcesCompat
import org.maphero.android.annotations.Marker
import org.maphero.android.annotations.MarkerOptions
import org.maphero.android.camera.CameraUpdateFactory
import org.maphero.android.geometry.LatLng
import org.maphero.android.maps.MapView
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.MapHeroMap.InfoWindowAdapter
import org.maphero.android.maps.MapHeroMap.OnMapClickListener
import org.maphero.android.maps.OnMapReadyCallback
import org.maplibre.android.testapp.R
import org.maphero.android.testapp.styles.TestStyles
import org.maphero.android.testapp.utils.IconUtils
import java.util.*

/**
 * Test activity showcasing how to dynamically update InfoWindow when Using an MapHeroMap.InfoWindowAdapter.
 */
class DynamicInfoWindowAdapterActivity : AppCompatActivity(), OnMapReadyCallback {
    private lateinit var mapHeroMap1: MapHeroMap
    private lateinit var mapView: MapView
    private var marker: Marker? = null
    private val mapClickListener = OnMapClickListener { point ->
        if (marker == null) {
            return@OnMapClickListener false
        }

        // Distance from click to marker
        val distanceKm = marker!!.position.distanceTo(point) / 1000

        // Get the info window
        val infoWindow = marker!!.infoWindow

        // Get the view from the info window
        if (infoWindow != null && infoWindow.view != null) {
            // Set the new text on the text view in the info window
            val textView = infoWindow.view as TextView?
            textView!!.text = String.format(Locale.getDefault(), "%.2fkm", distanceKm)
            // Update the info window position (as the text length changes)
            textView.post { infoWindow.update() }
        }
        true
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_infowindow_adapter)
        mapView = findViewById(R.id.mapView)
        mapView.onCreate(savedInstanceState)
        mapView.getMapAsync(this)
    }

    override fun onMapReady(mapHeroMap: MapHeroMap) {
        mapHeroMap1 = mapHeroMap
        mapHeroMap.setStyle(TestStyles.getPredefinedStyleWithFallback("Streets"))

        // Add info window adapter
        addCustomInfoWindowAdapter(mapHeroMap1)

        // Keep info windows open on click
        mapHeroMap1.uiSettings.isDeselectMarkersOnTap = false

        // Add a marker
        marker = addMarker(mapHeroMap1)
        mapHeroMap1.selectMarker(marker!!)

        // On map click, change the info window contents
        mapHeroMap1.addOnMapClickListener(mapClickListener)

        // Focus on Paris
        mapHeroMap1.animateCamera(CameraUpdateFactory.newLatLng(PARIS))
    }

    private fun addMarker(mapHeroMap: MapHeroMap): Marker {
        return mapHeroMap.addMarker(
            MarkerOptions()
                .position(PARIS)
                .icon(
                    IconUtils.drawableToIcon(
                        this,
                        R.drawable.ic_location_city,
                        ResourcesCompat.getColor(resources, R.color.maplibre_blue, theme)
                    )
                )
        )
    }

    private fun addCustomInfoWindowAdapter(mapHeroMap: MapHeroMap) {
        val padding = resources.getDimension(R.dimen.attr_margin).toInt()
        mapHeroMap.infoWindowAdapter = InfoWindowAdapter { marker: Marker ->
            val textView = TextView(this@DynamicInfoWindowAdapterActivity)
            textView.text = marker.title
            textView.setBackgroundColor(Color.WHITE)
            textView.setText(R.string.action_calculate_distance)
            textView.setPadding(padding, padding, padding, padding)
            textView
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
        if (this::mapHeroMap1.isInitialized) {
            mapHeroMap1.removeOnMapClickListener(mapClickListener)
        }
        mapView.onDestroy()
    }

    override fun onLowMemory() {
        super.onLowMemory()
        mapView.onLowMemory()
    }

    companion object {
        private val PARIS = LatLng(48.864716, 2.349014)
    }
}
