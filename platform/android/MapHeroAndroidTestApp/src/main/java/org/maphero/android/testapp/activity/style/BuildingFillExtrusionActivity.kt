package org.maphero.android.testapp.activity.style

import android.graphics.Color
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import org.maphero.android.maps.MapView
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.OnMapReadyCallback
import org.maphero.android.maps.Style
import org.maphero.android.style.expressions.Expression
import org.maphero.android.style.layers.FillExtrusionLayer
import org.maphero.android.style.layers.Property
import org.maphero.android.style.layers.PropertyFactory
import org.maphero.android.style.light.Light
import org.maphero.android.style.light.Position
import org.maphero.android.testapp.R
import org.maphero.android.testapp.styles.TestStyles
import org.maphero.android.utils.ColorUtils

/**
 * Test activity showing 3D buildings with a FillExtrusion Layer
 */
class BuildingFillExtrusionActivity : AppCompatActivity() {
    private lateinit var mapView: MapView
    private lateinit var maplibreMap: MapHeroMap
    private var light: Light? = null
    private var isMapAnchorLight = false
    private var isLowIntensityLight = false
    private var isRedColor = false
    private var isInitPosition = false
    public override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_building_layer)
        mapView = findViewById(R.id.mapView)
        mapView.onCreate(savedInstanceState)
        mapView.getMapAsync(
            OnMapReadyCallback { map: MapHeroMap? ->
                if (map != null) {
                    maplibreMap = map
                }
                maplibreMap.setStyle(TestStyles.OPENFREEMAP_BRIGHT) { style: Style ->
                    setupBuildings(style)
                    setupLight()
                }
            }
        )
    }

    private fun setupBuildings(style: Style) {
        // --8<-- [start:setupBuildings]
        val fillExtrusionLayer = FillExtrusionLayer("building-3d", "openmaptiles")
        fillExtrusionLayer.sourceLayer = "building"
        fillExtrusionLayer.setFilter(
            Expression.all(
                Expression.has("render_height"),
                Expression.has("render_min_height")
            )
        )
        fillExtrusionLayer.minZoom = 15f
        fillExtrusionLayer.setProperties(
            PropertyFactory.fillExtrusionColor(Color.LTGRAY),
            PropertyFactory.fillExtrusionHeight(Expression.get("render_height")),
            PropertyFactory.fillExtrusionBase(Expression.get("render_min_height")),
            PropertyFactory.fillExtrusionOpacity(0.9f)
        )
        style.addLayer(fillExtrusionLayer)
        // --8<-- [end:setupBuildings]
    }

    private fun setupLight() {
        light = maplibreMap.style!!.light
        findViewById<View>(R.id.fabLightPosition).setOnClickListener { v: View? ->
            // --8<-- [start:lightPosition]
            isInitPosition = !isInitPosition
            if (isInitPosition) {
                light!!.position = Position(1.5f, 90f, 80f)
            } else {
                light!!.position = Position(1.15f, 210f, 30f)
            }
            // --8<-- [end:lightPosition]
        }
        findViewById<View>(R.id.fabLightColor).setOnClickListener { v: View? ->
            // --8<-- [start:lightColor]
            isRedColor = !isRedColor
            light!!.setColor(ColorUtils.colorToRgbaString(if (isRedColor) Color.RED else Color.BLUE))
            // --8<-- [end:lightColor]
        }
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.menu_building, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        if (light != null) {
            val id = item.itemId
            if (id == R.id.menu_action_anchor) {
                isMapAnchorLight = !isMapAnchorLight
                light!!.anchor =
                    if (isMapAnchorLight) Property.ANCHOR_MAP else Property.ANCHOR_VIEWPORT
            } else if (id == R.id.menu_action_intensity) {
                isLowIntensityLight = !isLowIntensityLight
                light!!.intensity = if (isLowIntensityLight) 0.35f else 1.0f
            }
        }
        return super.onOptionsItemSelected(item)
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

    public override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        mapView.onSaveInstanceState(outState)
    }

    override fun onLowMemory() {
        super.onLowMemory()
        mapView.onLowMemory()
    }

    public override fun onDestroy() {
        super.onDestroy()
        mapView.onDestroy()
    }
}
