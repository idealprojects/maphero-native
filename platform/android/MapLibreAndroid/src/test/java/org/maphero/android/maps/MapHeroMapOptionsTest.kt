package org.maphero.android.maps

import android.graphics.Color
import android.view.Gravity
import org.maphero.android.camera.CameraPosition
import org.maphero.android.constants.MapHeroConstants
import org.maphero.android.geometry.LatLng
import org.junit.Assert
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import java.util.*

@RunWith(RobolectricTestRunner::class)
class MapHeroMapOptionsTest {
    @Test
    fun testSanity() {
        Assert.assertNotNull("should not be null",
            MapHeroMapOptions()
        )
    }

    @Test
    fun testDebugEnabled() {
        Assert.assertFalse(MapHeroMapOptions().debugActive)
        Assert.assertTrue(MapHeroMapOptions().debugActive(true).debugActive)
        Assert.assertFalse(MapHeroMapOptions().debugActive(false).debugActive)
    }

    @Test
    fun testCompassEnabled() {
        Assert.assertTrue(MapHeroMapOptions().compassEnabled(true).compassEnabled)
        Assert.assertFalse(MapHeroMapOptions().compassEnabled(false).compassEnabled)
    }

    @Test
    fun testCompassGravity() {
        Assert.assertEquals(
            Gravity.TOP or Gravity.END,
            MapHeroMapOptions().compassGravity
        )
        Assert.assertEquals(
            Gravity.BOTTOM,
            MapHeroMapOptions().compassGravity(Gravity.BOTTOM).compassGravity
        )
        Assert.assertNotEquals(
            Gravity.START.toLong(),
            MapHeroMapOptions().compassGravity(Gravity.BOTTOM).compassGravity.toLong()
        )
    }

    @Test
    fun testCompassMargins() {
        Assert.assertTrue(
            Arrays.equals(
                intArrayOf(0, 1, 2, 3),
                MapHeroMapOptions()
                    .compassMargins(intArrayOf(0, 1, 2, 3)).compassMargins
            )
        )
        Assert.assertFalse(
            Arrays.equals(
                intArrayOf(0, 1, 2, 3),
                MapHeroMapOptions()
                    .compassMargins(intArrayOf(0, 0, 0, 0)).compassMargins
            )
        )
    }

    @Test
    fun testLogoEnabled() {
        Assert.assertTrue(MapHeroMapOptions().logoEnabled(true).logoEnabled)
        Assert.assertFalse(MapHeroMapOptions().logoEnabled(false).logoEnabled)
    }

    @Test
    fun testLogoGravity() {
        Assert.assertEquals(
            Gravity.BOTTOM or Gravity.START,
            MapHeroMapOptions().logoGravity
        )
        Assert.assertEquals(
            Gravity.BOTTOM,
            MapHeroMapOptions().logoGravity(Gravity.BOTTOM).logoGravity
        )
        Assert.assertNotEquals(
            Gravity.START.toLong(),
            MapHeroMapOptions().logoGravity(Gravity.BOTTOM).logoGravity.toLong()
        )
    }

    @Test
    fun testLogoMargins() {
        Assert.assertTrue(
            Arrays.equals(
                intArrayOf(0, 1, 2, 3),
                MapHeroMapOptions()
                    .logoMargins(intArrayOf(0, 1, 2, 3)).logoMargins
            )
        )
        Assert.assertFalse(
            Arrays.equals(
                intArrayOf(0, 1, 2, 3),
                MapHeroMapOptions()
                    .logoMargins(intArrayOf(0, 0, 0, 0)).logoMargins
            )
        )
    }

    @Test
    fun testAttributionTintColor() {
        Assert.assertEquals(-1, MapHeroMapOptions().attributionTintColor)
        Assert.assertEquals(
            Color.RED,
            MapHeroMapOptions().attributionTintColor(Color.RED).attributionTintColor
        )
    }

    @Test
    fun testAttributionEnabled() {
        Assert.assertTrue(MapHeroMapOptions().attributionEnabled(true).attributionEnabled)
        Assert.assertFalse(MapHeroMapOptions().attributionEnabled(false).attributionEnabled)
    }

    @Test
    fun testAttributionGravity() {
        Assert.assertEquals(
            Gravity.BOTTOM or Gravity.START,
            MapHeroMapOptions().attributionGravity
        )
        Assert.assertEquals(
            Gravity.BOTTOM,
            MapHeroMapOptions().attributionGravity(Gravity.BOTTOM).attributionGravity
        )
        Assert.assertNotEquals(
            Gravity.START.toLong(),
            MapHeroMapOptions().attributionGravity(Gravity.BOTTOM).attributionGravity.toLong()
        )
    }

    @Test
    fun testAttributionMargins() {
        Assert.assertTrue(
            Arrays.equals(
                intArrayOf(0, 1, 2, 3),
                MapHeroMapOptions()
                    .attributionMargins(intArrayOf(0, 1, 2, 3)).attributionMargins
            )
        )
        Assert.assertFalse(
            Arrays.equals(
                intArrayOf(0, 1, 2, 3),
                MapHeroMapOptions()
                    .attributionMargins(intArrayOf(0, 0, 0, 0)).attributionMargins
            )
        )
    }

    @Test
    fun testMinZoom() {
        Assert.assertEquals(
            MapHeroConstants.MINIMUM_ZOOM.toDouble(),
            MapHeroMapOptions().minZoomPreference,
            DELTA
        )
        Assert.assertEquals(
            5.0,
            MapHeroMapOptions().minZoomPreference(5.0).minZoomPreference,
            DELTA
        )
        Assert.assertNotEquals(
            2.0,
            MapHeroMapOptions().minZoomPreference(5.0).minZoomPreference,
            DELTA
        )
    }

    @Test
    fun testMaxZoom() {
        Assert.assertEquals(
            MapHeroConstants.MAXIMUM_ZOOM.toDouble(),
            MapHeroMapOptions().maxZoomPreference,
            DELTA
        )
        Assert.assertEquals(
            5.0,
            MapHeroMapOptions().maxZoomPreference(5.0).maxZoomPreference,
            DELTA
        )
        Assert.assertNotEquals(
            2.0,
            MapHeroMapOptions().maxZoomPreference(5.0).maxZoomPreference,
            DELTA
        )
    }

    @Test
    fun testMinPitch() {
        Assert.assertEquals(
            MapHeroConstants.MINIMUM_PITCH.toDouble(),
            MapHeroMapOptions().minPitchPreference,
            DELTA
        )
        Assert.assertEquals(
            5.0,
            MapHeroMapOptions().minPitchPreference(5.0).minPitchPreference,
            DELTA
        )
        Assert.assertNotEquals(
            2.0,
            MapHeroMapOptions().minPitchPreference(5.0).minPitchPreference,
            DELTA
        )
    }

    @Test
    fun testMaxPitch() {
        Assert.assertEquals(
            MapHeroConstants.MAXIMUM_PITCH.toDouble(),
            MapHeroMapOptions().maxPitchPreference,
            DELTA
        )
        Assert.assertEquals(
            5.0,
            MapHeroMapOptions().maxPitchPreference(5.0).maxPitchPreference,
            DELTA
        )
        Assert.assertNotEquals(
            2.0,
            MapHeroMapOptions().maxPitchPreference(5.0).maxPitchPreference,
            DELTA
        )
    }

    @Test
    fun testTiltGesturesEnabled() {
        Assert.assertTrue(MapHeroMapOptions().tiltGesturesEnabled)
        Assert.assertTrue(MapHeroMapOptions().tiltGesturesEnabled(true).tiltGesturesEnabled)
        Assert.assertFalse(MapHeroMapOptions().tiltGesturesEnabled(false).tiltGesturesEnabled)
    }

    @Test
    fun testScrollGesturesEnabled() {
        Assert.assertTrue(MapHeroMapOptions().scrollGesturesEnabled)
        Assert.assertTrue(MapHeroMapOptions().scrollGesturesEnabled(true).scrollGesturesEnabled)
        Assert.assertFalse(MapHeroMapOptions().scrollGesturesEnabled(false).scrollGesturesEnabled)
    }

    @Test
    fun testHorizontalScrollGesturesEnabled() {
        Assert.assertTrue(MapHeroMapOptions().horizontalScrollGesturesEnabled)
        Assert.assertTrue(MapHeroMapOptions().horizontalScrollGesturesEnabled(true).horizontalScrollGesturesEnabled)
        Assert.assertFalse(MapHeroMapOptions().horizontalScrollGesturesEnabled(false).horizontalScrollGesturesEnabled)
    }

    @Test
    fun testZoomGesturesEnabled() {
        Assert.assertTrue(MapHeroMapOptions().zoomGesturesEnabled)
        Assert.assertTrue(MapHeroMapOptions().zoomGesturesEnabled(true).zoomGesturesEnabled)
        Assert.assertFalse(MapHeroMapOptions().zoomGesturesEnabled(false).zoomGesturesEnabled)
    }

    @Test
    fun testRotateGesturesEnabled() {
        Assert.assertTrue(MapHeroMapOptions().rotateGesturesEnabled)
        Assert.assertTrue(MapHeroMapOptions().rotateGesturesEnabled(true).rotateGesturesEnabled)
        Assert.assertFalse(MapHeroMapOptions().rotateGesturesEnabled(false).rotateGesturesEnabled)
    }

    @Test
    fun testCamera() {
        val position = CameraPosition.Builder().build()
        Assert.assertEquals(
            CameraPosition.Builder(position).build(),
            MapHeroMapOptions().camera(position).camera
        )
        Assert.assertNotEquals(
            CameraPosition.Builder().target(LatLng(1.0, 1.0)),
            MapHeroMapOptions().camera(position)
        )
        Assert.assertNull(MapHeroMapOptions().camera)
    }

    @Test
    fun testPrefetchesTiles() {
        // Default value
        Assert.assertTrue(MapHeroMapOptions().prefetchesTiles)

        // Check mutations
        Assert.assertTrue(MapHeroMapOptions().setPrefetchesTiles(true).prefetchesTiles)
        Assert.assertFalse(MapHeroMapOptions().setPrefetchesTiles(false).prefetchesTiles)
    }

    @Test
    fun testPrefetchZoomDelta() {
        // Default value
        Assert.assertEquals(4, MapHeroMapOptions().prefetchZoomDelta)

        // Check mutations
        Assert.assertEquals(
            5,
            MapHeroMapOptions().setPrefetchZoomDelta(5).prefetchZoomDelta
        )
    }

    @Test
    fun testCrossSourceCollisions() {
        // Default value
        Assert.assertTrue(MapHeroMapOptions().crossSourceCollisions)

        // check mutations
        Assert.assertTrue(MapHeroMapOptions().crossSourceCollisions(true).crossSourceCollisions)
        Assert.assertFalse(MapHeroMapOptions().crossSourceCollisions(false).crossSourceCollisions)
    }

    @Test
    fun testLocalIdeographFontFamily_enabledByDefault() {
        val options = MapHeroMapOptions.createFromAttributes(RuntimeEnvironment.application, null)
        Assert.assertEquals(
            MapHeroConstants.DEFAULT_FONT,
            options.localIdeographFontFamily
        )
    }

    companion object {
        private const val DELTA = 1e-15
    }
}
