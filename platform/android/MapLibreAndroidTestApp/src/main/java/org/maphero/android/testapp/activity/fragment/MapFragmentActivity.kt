package org.maphero.android.testapp.activity.fragment

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import org.maphero.android.camera.CameraPosition
import org.maphero.android.camera.CameraUpdateFactory
import org.maphero.android.geometry.LatLng
import org.maphero.android.maps.* // ktlint-disable no-wildcard-imports
import org.maphero.android.maps.MapFragment.OnMapViewReadyCallback
import org.maphero.android.maps.MapView.OnDidFinishRenderingFrameListener
import org.maplibre.android.testapp.R
import org.maphero.android.testapp.styles.TestStyles

/**
 * Test activity showcasing using the MapFragment API using SDK Fragments.
 *
 *
 * Uses MapHeroMapOptions to initialise the Fragment.
 *
 */
class MapFragmentActivity :
    AppCompatActivity(),
    OnMapViewReadyCallback,
    OnMapReadyCallback,
    OnDidFinishRenderingFrameListener {
    private lateinit var mapHeroMap1: MapHeroMap
    private lateinit var mapView: MapView
    private var initialCameraAnimation = true
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_map_fragment)
        val mapFragment: MapFragment
        if (savedInstanceState == null) {
            mapFragment = MapFragment.newInstance(createFragmentOptions())
            supportFragmentManager
                .beginTransaction()
                .add(R.id.fragment_container, mapFragment, TAG)
                .commit()
        } else {
            mapFragment = supportFragmentManager.findFragmentByTag(TAG) as MapFragment
        }
        mapFragment.getMapAsync(this)
    }

    private fun createFragmentOptions(): MapHeroMapOptions {
        val options = MapHeroMapOptions.createFromAttributes(this, null)
        options.scrollGesturesEnabled(false)
        options.zoomGesturesEnabled(false)
        options.tiltGesturesEnabled(false)
        options.rotateGesturesEnabled(false)
        options.debugActive(false)
        val dc = LatLng(38.90252, -77.02291)
        options.minZoomPreference(9.0)
        options.maxZoomPreference(11.0)
        options.camera(
            CameraPosition.Builder()
                .target(dc)
                .zoom(11.0)
                .build()
        )
        return options
    }

    override fun onMapViewReady(map: MapView) {
        mapView = map
        mapView.addOnDidFinishRenderingFrameListener(this)
    }

    override fun onMapReady(mapHeroMap: MapHeroMap) {
        mapHeroMap1 = mapHeroMap
        mapHeroMap1.setStyle(TestStyles.getPredefinedStyleWithFallback("Outdoor"))
    }

    override fun onDestroy() {
        super.onDestroy()
        if (this::mapView.isInitialized) {
            mapView.removeOnDidFinishRenderingFrameListener(this)
        }
    }

    override fun onDidFinishRenderingFrame(fully: Boolean, frameEncodingTime: Double, frameRenderingTime: Double) {
        if (initialCameraAnimation && fully && this::mapHeroMap1.isInitialized) {
            mapHeroMap1.animateCamera(
                CameraUpdateFactory.newCameraPosition(CameraPosition.Builder().tilt(45.0).build()),
                5000
            )
            initialCameraAnimation = false
        }
    }

    companion object {
        private const val TAG = "com.mapbox.map"
    }
}
