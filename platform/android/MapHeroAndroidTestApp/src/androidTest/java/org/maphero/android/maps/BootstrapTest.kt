package org.maphero.android.maps

import androidx.test.annotation.UiThreadTest
import androidx.test.internal.runner.junit4.AndroidJUnit4ClassRunner
import androidx.test.platform.app.InstrumentationRegistry
import org.maphero.android.AppCenter
import org.maphero.android.MapHero
import org.maphero.android.WellKnownTileServer
import org.maphero.android.storage.FileSource
import org.maphero.android.util.TileServerOptions
import org.junit.*
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4ClassRunner::class)
class BootstrapTest : AppCenter() {

    var apiKeyBackup: String? = null

    @Before
    @UiThreadTest
    fun before() {
        apiKeyBackup = MapHero.getApiKey()
    }

    @After
    @UiThreadTest
    fun after() {
        val context = InstrumentationRegistry.getInstrumentation().context
        MapHero.getInstance(context)
    }

    @Test
    @UiThreadTest
    fun defaultBootstrap() {
        val context = InstrumentationRegistry.getInstrumentation().context

        MapHero.getInstance(context)

        val tileServerOptions = TileServerOptions.get(WellKnownTileServer.MapHero)
        Assert.assertTrue(
            Style.getPredefinedStyles().count() == tileServerOptions.defaultStyles.count()
        )
        Assert.assertTrue(
            Style.getPredefinedStyles().first().url == tileServerOptions.defaultStyles.first().url
        )

        val fileSource = FileSource.getInstance(context)
        Assert.assertEquals(fileSource.apiBaseUrl, tileServerOptions.baseURL)
    }

    @Test
    @UiThreadTest
    fun maptilerBootstrap() {
        val context = InstrumentationRegistry.getInstrumentation().context

        val key = "abcdef"
        MapHero.getInstance(context, key, WellKnownTileServer.MapTiler)

        val tileServerOptions = TileServerOptions.get(WellKnownTileServer.MapTiler)
        Assert.assertTrue(
            Style.getPredefinedStyles().count() == tileServerOptions.defaultStyles.count()
        )
        Assert.assertTrue(
            Style.getPredefinedStyles().first().url == tileServerOptions.defaultStyles.first().url
        )

        val fileSource = FileSource.getInstance(context)
        Assert.assertEquals(fileSource.apiBaseUrl, tileServerOptions.baseURL)
        Assert.assertEquals(fileSource.apiKey, key)
    }

    @Test
    @UiThreadTest
    fun duplicateBootstrap() {
        val context = InstrumentationRegistry.getInstrumentation().context

        val key = "pk.abcdef"

        MapHero.getInstance(context, key, WellKnownTileServer.MapTiler)
        MapHero.getInstance(context)
        MapHero.getInstance(context, key, WellKnownTileServer.Mapbox)

        val tileServerOptions = TileServerOptions.get(WellKnownTileServer.Mapbox)
        Assert.assertTrue(
            Style.getPredefinedStyles().count() == tileServerOptions.defaultStyles.count()
        )
        Assert.assertTrue(
            Style.getPredefinedStyles().first().url == tileServerOptions.defaultStyles.first().url
        )

        val fileSource = FileSource.getInstance(context)
        Assert.assertEquals(fileSource.apiBaseUrl, tileServerOptions.baseURL)
        Assert.assertEquals(fileSource.apiKey, key)
    }
}
