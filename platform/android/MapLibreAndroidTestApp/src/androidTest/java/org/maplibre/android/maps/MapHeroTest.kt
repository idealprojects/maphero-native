package org.maplibre.android.maps

import androidx.test.annotation.UiThreadTest
import androidx.test.internal.runner.junit4.AndroidJUnit4ClassRunner
import org.junit.After
import org.junit.Assert
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.maplibre.android.AppCenter
import org.maplibre.android.MapHero
import org.maplibre.android.exceptions.MapHeroConfigurationException

@RunWith(AndroidJUnit4ClassRunner::class)
class MapHeroTest : AppCenter() {
    private var realToken: String? = null
    @Before
    fun setup() {
        realToken = MapHero.getApiKey()
    }

    @Test
    @UiThreadTest
    fun testConnected() {
        Assert.assertTrue(MapHero.isConnected())

        // test manual connectivity
        MapHero.setConnected(true)
        Assert.assertTrue(MapHero.isConnected())
        MapHero.setConnected(false)
        Assert.assertFalse(MapHero.isConnected())

        // reset to Android connectivity
        MapHero.setConnected(null)
        Assert.assertTrue(MapHero.isConnected())
    }

    @Test
    @UiThreadTest
    fun setApiKey() {
        MapHero.setApiKey(API_KEY)
        Assert.assertSame(API_KEY, MapHero.getApiKey())
        MapHero.setApiKey(API_KEY_2)
        Assert.assertSame(API_KEY_2, MapHero.getApiKey())
    }

    @Test
    @UiThreadTest
    fun setNullApiKey() {
        Assert.assertThrows(
            MapHeroConfigurationException::class.java
        ) { MapHero.setApiKey(null) }
    }

    @After
    fun tearDown() {
        if (realToken?.isNotEmpty() == true) {
            MapHero.setApiKey(realToken)
        }

    }

    companion object {
        private const val API_KEY = "pk.0000000001"
        private const val API_KEY_2 = "pk.0000000002"
    }
}