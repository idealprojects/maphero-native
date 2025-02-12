package org.maphero.android.testapp.activity.feature

import android.graphics.Color
import android.os.Bundle
import android.os.Parcel
import android.os.Parcelable
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import org.maplibre.geojson.Feature
import org.maphero.android.annotations.BaseMarkerOptions
import org.maphero.android.annotations.Marker
import org.maphero.android.maps.MapView
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.MapHeroMap.InfoWindowAdapter
import org.maphero.android.maps.MapHeroMap.OnMapClickListener
import org.maphero.android.maps.Style
import org.maphero.android.testapp.R
import org.maphero.android.testapp.styles.TestStyles
import timber.log.Timber

/**
 * Test activity showcasing using the query rendered features API to query feature properties on Map click.
 */
class QueryRenderedFeaturesPropertiesActivity : AppCompatActivity() {
    lateinit var mapView: MapView
    lateinit var mapHeroMap: MapHeroMap
        private set
    private var marker: Marker? = null
    private val mapClickListener = OnMapClickListener { point ->
        val density = resources.displayMetrics.density
        val pixel = mapHeroMap.projection.toScreenLocation(point)
        Timber.i(
            "Requesting features for %sx%s (%sx%s adjusted for density)",
            pixel.x,
            pixel.y,
            pixel.x / density,
            pixel.y / density
        )
        val features = mapHeroMap.queryRenderedFeatures(pixel)

        // Debug output
        debugOutput(features)

        // Remove any previous markers
        if (marker != null) {
            mapHeroMap.removeMarker(marker!!)
        }

        // Add a marker on the clicked point
        marker = mapHeroMap.addMarker(CustomMarkerOptions().position(point)!!.features(features))
        mapHeroMap.selectMarker(marker!!)
        true
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_query_features_point)

        // Initialize map as normal
        mapView = findViewById<View>(R.id.mapView) as MapView
        mapView.onCreate(savedInstanceState)
        mapView.getMapAsync { mapHeroMap1: MapHeroMap ->
            mapHeroMap1.setStyle(TestStyles.getPredefinedStyleWithFallback("Streets")) { style: Style? ->
                this@QueryRenderedFeaturesPropertiesActivity.mapHeroMap = mapHeroMap1

                // Add custom window adapter
                addCustomInfoWindowAdapter(mapHeroMap1)

                // Add a click listener
                mapHeroMap1.addOnMapClickListener(mapClickListener)
            }
        }
    }

    private fun debugOutput(features: List<Feature>) {
        Timber.i("Got %s features", features.size)
        for (feature in features) {
            Timber.i(
                "Got feature %s with %s properties and Geometry %s",
                feature.id(),
                if (feature.properties() != null) {
                    feature.properties()!!
                        .entrySet().size
                } else {
                    "<null>"
                },
                if (feature.geometry() != null) {
                    feature.geometry()!!::class.java.simpleName
                } else {
                    "<null>"
                }
            )
            if (feature.properties() != null) {
                for ((key, value) in feature.properties()!!.entrySet()) {
                    Timber.i("Prop %s - %s", key, value)
                }
            }
        }
    }

    private fun addCustomInfoWindowAdapter(mapHeroMap1: MapHeroMap) {
        mapHeroMap1.infoWindowAdapter = object : InfoWindowAdapter {
            private fun row(text: String): TextView {
                val view = TextView(this@QueryRenderedFeaturesPropertiesActivity)
                view.text = text
                return view
            }

            override fun getInfoWindow(marker: Marker): View? {
                val customMarker = marker as CustomMarker
                val view = LinearLayout(this@QueryRenderedFeaturesPropertiesActivity)
                view.orientation = LinearLayout.VERTICAL
                view.setBackgroundColor(Color.WHITE)
                if (customMarker.features!!.size > 0) {
                    view.addView(
                        row(
                            String.format(
                                "Found %s features",
                                customMarker.features.size
                            )
                        )
                    )
                    val feature = customMarker.features[0]
                    for ((key, value) in feature.properties()!!.entrySet()) {
                        view.addView(row(String.format("%s: %s", key, value)))
                    }
                } else {
                    view.addView(row("No features here"))
                }
                return view
            }
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
        if (this::mapHeroMap.isInitialized) {
            mapHeroMap.removeOnMapClickListener(mapClickListener)
        }
        mapView.onDestroy()
    }

    override fun onLowMemory() {
        super.onLowMemory()
        mapView.onLowMemory()
    }

    private class CustomMarker constructor(
        baseMarkerOptions: BaseMarkerOptions<*, *>?,
        val features: List<Feature>?
    ) : Marker(baseMarkerOptions)

    private class CustomMarkerOptions : BaseMarkerOptions<CustomMarker?, CustomMarkerOptions?> {
        private var features: List<Feature>? = null
        fun features(features: List<Feature>?): CustomMarkerOptions {
            this.features = features
            return this
        }

        internal constructor() {}
        private constructor(`in`: Parcel) {
            // Should implement this
        }

        override fun getThis(): CustomMarkerOptions {
            return this
        }

        override fun getMarker(): CustomMarker {
            return CustomMarker(this, features)
        }

        override fun describeContents(): Int {
            return 0
        }

        override fun writeToParcel(out: Parcel, flags: Int) {
            // Should implement this
        }

        companion object {
            @JvmField
            val CREATOR: Parcelable.Creator<CustomMarkerOptions?> =
                object : Parcelable.Creator<CustomMarkerOptions?> {
                    override fun createFromParcel(`in`: Parcel): CustomMarkerOptions? {
                        return CustomMarkerOptions(`in`)
                    }

                    override fun newArray(size: Int): Array<CustomMarkerOptions?> {
                        return arrayOfNulls(size)
                    }
                }
        }
    }
}
