package org.maphero.android.testapp.activity.fragment

import android.os.Bundle
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.SupportMapFragment
import org.maphero.android.testapp.R
import org.maphero.android.testapp.databinding.ActivityBackstackFragmentBinding
import org.maphero.android.testapp.styles.TestStyles
import org.maphero.android.testapp.utils.NavUtils

/**
 * Test activity showcasing using the MapFragment API as part of a backstacked fragment.
 */
class FragmentBackStackActivity : AppCompatActivity() {

    companion object {
        private const val FRAGMENT_TAG = "map_fragment"
    }

    private lateinit var binding: ActivityBackstackFragmentBinding
    private lateinit var mapFragment: SupportMapFragment

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityBackstackFragmentBinding.inflate(layoutInflater)
        setContentView(binding.root)

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (supportFragmentManager.backStackEntryCount == 0) {
                    // activity uses singleInstance for testing purposes
                    // code below provides a default navigation when using the app
                    NavUtils.navigateHome(this@FragmentBackStackActivity)
                } else {
                    finish()
                }
            }
        })

        if (savedInstanceState == null) {
            mapFragment = SupportMapFragment.newInstance()
            mapFragment.getMapAsync { initMap(it) }

            supportFragmentManager.beginTransaction().apply {
                add(R.id.container, mapFragment, FRAGMENT_TAG)
            }.commit()
        } else {
            supportFragmentManager.findFragmentByTag(FRAGMENT_TAG)?.also { fragment ->
                if (fragment is SupportMapFragment) {
                    fragment.getMapAsync { initMap(it) }
                }
            }
        }

        binding.button.setOnClickListener { handleClick() }
    }

    private fun initMap(mapHeroMap: MapHeroMap) {
        try {
            val style = TestStyles.getPredefinedStyleWithFallback("Satellite Hybrid")
            mapHeroMap.setStyle(style) {
                mapHeroMap.setPadding(300, 300, 300, 300)
            }
        } catch (e: IllegalArgumentException) {
            // ignore style unavailable
        }
    }

    private fun handleClick() {
        supportFragmentManager.beginTransaction().apply {
            replace(R.id.container, NestedViewPagerActivity.ItemAdapter.EmptyFragment())
            addToBackStack("map_empty_fragment")
        }.commit()
    }
}
