package org.maphero.android.testapp.activity.storage

import android.os.Bundle
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import org.maphero.android.ModuleProvider
import org.maphero.android.ModuleProviderImpl
import org.maphero.android.maps.MapView
import org.maphero.android.MapHero
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.OnMapReadyCallback
import org.maphero.android.maps.Style
import org.maphero.android.testapp.R
import org.maphero.android.testapp.utils.ExampleCustomModuleProviderImpl

/**
 * This example activity shows how to provide your own HTTP request implementation.
 */
class CustomHttpRequestImplActivity : AppCompatActivity() {
    private lateinit var mapView: MapView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_data_driven_style)

        // Set a custom module provider that provides our custom HTTPRequestImpl
        MapHero.setModuleProvider(ExampleCustomModuleProviderImpl() as ModuleProvider)

        // Initialize map with a style
        mapView = findViewById<View>(R.id.mapView) as MapView
        mapView.onCreate(savedInstanceState)
        mapView.getMapAsync(
            OnMapReadyCallback { mapHeroMap: MapHeroMap ->
                mapHeroMap.setStyle(Style.Builder().fromUri("https://demotiles.maplibre.org/style.json"))
            }
        )
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

        // Example of how to reset the module provider
        MapHero.setModuleProvider(ModuleProviderImpl())
        mapView.onDestroy()
    }

    override fun onLowMemory() {
        super.onLowMemory()
        mapView.onLowMemory()
    }
}
