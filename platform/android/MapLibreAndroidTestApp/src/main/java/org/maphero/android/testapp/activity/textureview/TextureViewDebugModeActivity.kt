package org.maphero.android.testapp.activity.textureview

import android.os.Bundle
import androidx.activity.OnBackPressedCallback
import org.maphero.android.maps.MapHeroMapOptions
import org.maphero.android.maps.OnMapReadyCallback
import org.maphero.android.testapp.activity.maplayout.DebugModeActivity
import org.maphero.android.testapp.utils.NavUtils

/**
 * Test activity showcasing the different debug modes and allows to cycle between the default map styles.
 */
class TextureViewDebugModeActivity : DebugModeActivity(), OnMapReadyCallback {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                // activity uses singleInstance for testing purposes
                // code below provides a default navigation when using the app
                NavUtils.navigateHome(this@TextureViewDebugModeActivity)
            }
        })
    }

    override fun setupMapHeroMapOptions(): MapHeroMapOptions {
        val mapHeroMapOptions = super.setupMapHeroMapOptions()
        mapHeroMapOptions.textureMode(true)
        return mapHeroMapOptions
    }
}
