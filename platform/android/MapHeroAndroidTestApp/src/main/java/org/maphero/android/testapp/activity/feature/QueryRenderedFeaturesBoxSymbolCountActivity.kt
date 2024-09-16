package org.maphero.android.testapp.activity.feature

import android.graphics.BitmapFactory
import android.graphics.RectF
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import org.maphero.android.maps.MapView
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.Style
import org.maphero.android.style.expressions.Expression
import org.maphero.android.style.layers.BackgroundLayer
import org.maphero.android.style.layers.PropertyFactory
import org.maphero.android.style.layers.SymbolLayer
import org.maphero.android.style.sources.GeoJsonSource
import org.maphero.android.testapp.R
import org.maphero.android.testapp.utils.ResourceUtils
import timber.log.Timber
import java.io.IOException

/**
 * Test activity showcasing using the query rendered features API to count Symbols in a rectangle.
 */
class QueryRenderedFeaturesBoxSymbolCountActivity : AppCompatActivity() {
    lateinit var mapView: MapView
    lateinit var mapHeroMap: MapHeroMap
        private set

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_query_features_box)
        val selectionBox = findViewById<View>(R.id.selection_box)

        // Initialize map as normal
        mapView = findViewById<View>(R.id.mapView) as MapView
        mapView.onCreate(savedInstanceState)
        mapView.getMapAsync { mapHeroMap1: MapHeroMap ->
            this@QueryRenderedFeaturesBoxSymbolCountActivity.mapHeroMap = mapHeroMap1
            try {
                val testPoints = ResourceUtils.readRawResource(
                    mapView.context,
                    R.raw.test_points_utrecht
                )
                val markerImage =
                    BitmapFactory.decodeResource(resources, R.drawable.maphero_marker_icon_default)
                mapHeroMap1.setStyle(
                    Style.Builder()
                        .withLayer(
                            BackgroundLayer("bg")
                                .withProperties(
                                    PropertyFactory.backgroundColor(Expression.rgb(120, 161, 226))
                                )
                        )
                        .withLayer(
                            SymbolLayer("symbols-layer", "symbols-source")
                                .withProperties(
                                    PropertyFactory.iconImage("test-icon")
                                )
                        )
                        .withSource(
                            GeoJsonSource("symbols-source", testPoints)
                        )
                        .withImage("test-icon", markerImage)
                )
            } catch (exception: IOException) {
                exception.printStackTrace()
            }
            selectionBox.setOnClickListener { view: View? ->
                // Query
                val top = selectionBox.top - mapView.top
                val left = selectionBox.left - mapView.left
                val box = RectF(
                    left.toFloat(),
                    top.toFloat(),
                    (left + selectionBox.width).toFloat(),
                    (top + selectionBox.height).toFloat()
                )
                Timber.i("Querying box %s", box)
                val features = mapHeroMap1.queryRenderedFeatures(box, "symbols-layer")

                // Show count
                 Toast.makeText(
                    this@QueryRenderedFeaturesBoxSymbolCountActivity,
                    "${features.size} feature${if (features.size == 1) "" else "s"} in box",
                    Toast.LENGTH_SHORT
                ).show()
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
        mapView.onDestroy()
    }

    override fun onLowMemory() {
        super.onLowMemory()
        mapView.onLowMemory()
    }
}
