package org.maphero.android.testapp.activity

import androidx.annotation.UiThread
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.Style
import org.maphero.android.testapp.activity.espresso.EspressoTestActivity
import org.maphero.android.testapp.styles.TestStyles

/**
 * Base class for all tests using EspressoTestActivity as wrapper.
 *
 *
 * Loads "assets/streets.json" as style.
 *
 */
open class EspressoTest : BaseTest() {
    override fun getActivityClass(): Class<*> {
        return EspressoTestActivity::class.java
    }

    @UiThread
    override fun initMap(maplibreMap: MapHeroMap) {
        maplibreMap.setStyle(Style.Builder().fromUri(TestStyles.VERSATILES))
        super.initMap(maplibreMap)
    }
}
