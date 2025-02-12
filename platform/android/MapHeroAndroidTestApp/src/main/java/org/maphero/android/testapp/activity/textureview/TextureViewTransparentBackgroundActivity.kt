package org.maphero.android.testapp.activity.textureview

import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import androidx.appcompat.app.AppCompatActivity
import org.maphero.android.camera.CameraPosition
import org.maphero.android.geometry.LatLng
import org.maphero.android.maps.*
import org.maphero.android.testapp.R
import org.maphero.android.testapp.utils.ResourceUtils
import timber.log.Timber
import java.io.IOException

/**
 * Example showcasing how to create a TextureView with a transparent background.
 */
class TextureViewTransparentBackgroundActivity : AppCompatActivity() {
    private lateinit var mapView: MapView
    private val mapHeroMap: MapHeroMap? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_textureview_transparent)
        setupBackground()
        setupMapView(savedInstanceState)
    }

    private fun setupBackground() {
        val imageView = findViewById<ImageView>(R.id.imageView)
        imageView.setImageResource(R.drawable.water)
        imageView.scaleType = ImageView.ScaleType.FIT_XY
    }

    private fun setupMapView(savedInstanceState: Bundle?) {
        val mapHeroMapOptions = MapHeroMapOptions.createFromAttributes(this, null)
        mapHeroMapOptions.translucentTextureSurface(true)
        mapHeroMapOptions.textureMode(true)
        mapHeroMapOptions.camera(
            CameraPosition.Builder()
                .zoom(2.0)
                .target(LatLng(48.507879, 8.363795))
                .build()
        )
        mapView = MapView(this, mapHeroMapOptions)
        mapView.onCreate(savedInstanceState)
        mapView.getMapAsync { mapHeroMap1: MapHeroMap -> initMap(mapHeroMap1) }
        (findViewById<View>(R.id.coordinator_layout) as ViewGroup).addView(mapView)
    }

    private fun initMap(mapHeroMap1: MapHeroMap) {
        try {
            mapHeroMap1.setStyle(
                Style.Builder().fromJson(ResourceUtils.readRawResource(this, R.raw.no_bg_style))
            )
        } catch (exception: IOException) {
            Timber.e(exception)
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
