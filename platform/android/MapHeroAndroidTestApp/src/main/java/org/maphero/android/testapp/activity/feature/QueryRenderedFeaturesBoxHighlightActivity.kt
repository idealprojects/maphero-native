package org.maphero.android.testapp.activity.feature

import android.graphics.Color
import android.graphics.RectF
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import org.maplibre.geojson.FeatureCollection
import org.maphero.android.maps.MapView
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.Style
import org.maphero.android.style.expressions.Expression
import org.maphero.android.style.layers.FillLayer
import org.maphero.android.style.layers.Layer
import org.maphero.android.style.layers.PropertyFactory
import org.maphero.android.style.sources.GeoJsonSource
import org.maphero.android.testapp.R
import org.maphero.android.testapp.styles.TestStyles
import timber.log.Timber

/**
 * Demo's query rendered features
 */
class QueryRenderedFeaturesBoxHighlightActivity : AppCompatActivity() {
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
        mapView.getMapAsync { mapHeroMap: MapHeroMap ->
            this@QueryRenderedFeaturesBoxHighlightActivity.mapHeroMap = mapHeroMap

            // Add layer / source
            val source = GeoJsonSource("highlighted-shapes-source")
            val layer: Layer = FillLayer("highlighted-shapes-layer", "highlighted-shapes-source")
                .withProperties(PropertyFactory.fillColor(Color.RED))
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
                Timber.i("Querying box %s for buildings", box)
                val filter = Expression.lt(
                    Expression.toNumber(Expression.get("height")),
                    Expression.literal(10)
                )
                val features = mapHeroMap.queryRenderedFeatures(box, filter, "building")

                // Show count
                Toast.makeText(
                    this@QueryRenderedFeaturesBoxHighlightActivity,
                    String.format("%s features in box", features.size),
                    Toast.LENGTH_SHORT
                ).show()

                // Update source data
                source.setGeoJson(FeatureCollection.fromFeatures(features))
            }
            mapHeroMap.setStyle(
                Style.Builder()
                    .fromUri(TestStyles.getPredefinedStyleWithFallback("Streets"))
                    .withSource(source)
                    .withLayer(layer)
            )
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
