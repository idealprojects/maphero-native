package org.maphero.android.testapp.maps

import androidx.test.espresso.UiController
import androidx.test.internal.runner.junit4.AndroidJUnit4ClassRunner
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.Style
import org.maphero.android.style.layers.SymbolLayer
import org.maphero.android.style.sources.GeoJsonSource
import org.maphero.android.testapp.action.MapLibreMapAction
import org.maphero.android.testapp.activity.EspressoTest
import org.maphero.android.testapp.utils.TestingAsyncUtils
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4ClassRunner::class)
class StyleLoadTest : EspressoTest() {

    @Test
    fun updateSourceAfterStyleLoad() {
        validateTestSetup()
        MapLibreMapAction.invoke(maplibreMap) { uiController: UiController, maplibreMap: MapHeroMap ->
            val source = GeoJsonSource("id")
            val layer = SymbolLayer("id", "id")
            maplibreMap.setStyle(Style.Builder().withSource(source).withLayer(layer))
            TestingAsyncUtils.waitForLayer(uiController, mapView)
            maplibreMap.setStyle(Style.getPredefinedStyles()[0].url)
            TestingAsyncUtils.waitForLayer(uiController, mapView)
            source.setGeoJson("{}")
        }
    }
}
