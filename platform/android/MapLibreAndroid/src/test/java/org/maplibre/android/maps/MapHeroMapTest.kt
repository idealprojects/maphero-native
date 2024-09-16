package org.maplibre.android.maps

import android.content.Context
import org.maplibre.android.MapHeroInjector
import org.maplibre.android.camera.CameraPosition
import org.maplibre.android.camera.CameraUpdateFactory
import org.maplibre.android.constants.MapHeroConstants
import org.maplibre.android.geometry.LatLng
import org.maplibre.android.geometry.LatLngBounds
import org.maplibre.android.style.layers.TransitionOptions
import org.maplibre.android.utils.ConfigUtils
import io.mockk.*
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class MapHeroMapTest {

    private lateinit var mapHeroMap: MapHeroMap

    private lateinit var nativeMapView: NativeMap

    private lateinit var transform: Transform

    private lateinit var cameraChangeDispatcher: CameraChangeDispatcher

    private lateinit var developerAnimationListener: MapHeroMap.OnDeveloperAnimationListener

    @Mock
    private lateinit var context: Context

    @Mock
    private lateinit var appContext: Context

    @Before
    fun setup() {
        MockitoAnnotations.initMocks(this)
        MapHeroInjector.inject(context, "abcdef", ConfigUtils.getMockedOptions())
        cameraChangeDispatcher = spyk()
        developerAnimationListener = mockk(relaxed = true)
        nativeMapView = mockk(relaxed = true)
        transform = mockk(relaxed = true)
        mapHeroMap = MapHeroMap(
            nativeMapView,
            transform,
            mockk(relaxed = true),
            null,
            null,
            cameraChangeDispatcher,
            listOf(developerAnimationListener)
        )
        every { nativeMapView.isDestroyed } returns false
        every { nativeMapView.nativePtr } returns 5
        mapHeroMap.injectLocationComponent(spyk())
        mapHeroMap.setStyle(Style.getPredefinedStyle("Streets"))
        mapHeroMap.onFinishLoadingStyle()
    }

    @Test
    fun testTransitionOptions() {
        val expected = TransitionOptions(100, 200)
        mapHeroMap.style?.transition = expected
        verify { nativeMapView.transitionOptions = expected }
    }

    @Test
    fun testMoveCamera() {
        val callback = mockk<MapHeroMap.CancelableCallback>()
        val target = LatLng(1.0, 2.0)
        val expected = CameraPosition.Builder().target(target).build()
        val update = CameraUpdateFactory.newCameraPosition(expected)
        mapHeroMap.moveCamera(update, callback)
        verify { transform.moveCamera(mapHeroMap, update, callback) }
        verify { developerAnimationListener.onDeveloperAnimationStarted() }
    }

    @Test
    fun testEaseCamera() {
        val callback = mockk<MapHeroMap.CancelableCallback>()
        val target = LatLng(1.0, 2.0)
        val expected = CameraPosition.Builder().target(target).build()
        val update = CameraUpdateFactory.newCameraPosition(expected)
        mapHeroMap.easeCamera(update, callback)
        verify { transform.easeCamera(mapHeroMap, update, MapHeroConstants.ANIMATION_DURATION, true, callback) }
        verify { developerAnimationListener.onDeveloperAnimationStarted() }
    }

    @Test
    fun testAnimateCamera() {
        val callback = mockk<MapHeroMap.CancelableCallback>()
        val target = LatLng(1.0, 2.0)
        val expected = CameraPosition.Builder().target(target).build()
        val update = CameraUpdateFactory.newCameraPosition(expected)
        mapHeroMap.animateCamera(update, callback)
        verify { transform.animateCamera(mapHeroMap, update, MapHeroConstants.ANIMATION_DURATION, callback) }
        verify { developerAnimationListener.onDeveloperAnimationStarted() }
    }

    @Test
    fun testScrollBy() {
        mapHeroMap.scrollBy(100f, 200f)
        verify { nativeMapView.moveBy(100.0, 200.0, 0) }
        verify { developerAnimationListener.onDeveloperAnimationStarted() }
    }

    @Test
    fun testResetNorth() {
        mapHeroMap.resetNorth()
        verify { transform.resetNorth() }
        verify { developerAnimationListener.onDeveloperAnimationStarted() }
    }

    @Test
    fun testFocalBearing() {
        mapHeroMap.setFocalBearing(35.0, 100f, 200f, 1000)
        verify { transform.setBearing(35.0, 100f, 200f, 1000) }
        verify { developerAnimationListener.onDeveloperAnimationStarted() }
    }

    @Test
    fun testMinZoom() {
        mapHeroMap.setMinZoomPreference(10.0)
        verify { transform.minZoom = 10.0 }
    }

    @Test
    fun testMaxZoom() {
        mapHeroMap.setMaxZoomPreference(10.0)
        verify { transform.maxZoom = 10.0 }
    }

    @Test
    fun testMinPitch() {
        mapHeroMap.setMinPitchPreference(10.0)
        verify { transform.minPitch = 10.0 }
    }

    @Test
    fun testMaxPitch() {
        mapHeroMap.setMaxPitchPreference(10.0)
        verify { transform.maxPitch = 10.0 }
    }

    @Test
    fun testFpsListener() {
        val fpsChangedListener = mockk<MapHeroMap.OnFpsChangedListener>()
        mapHeroMap.onFpsChangedListener = fpsChangedListener
        assertEquals("Listener should match", fpsChangedListener, mapHeroMap.onFpsChangedListener)
    }

    @Test
    fun testTilePrefetch() {
        mapHeroMap.prefetchesTiles = true
        verify { nativeMapView.prefetchTiles = true }
    }

    @Test
    fun testGetPrefetchZoomDelta() {
        every { nativeMapView.prefetchZoomDelta } answers { 3 }
        assertEquals(3, mapHeroMap.prefetchZoomDelta)
    }

    @Test
    fun testSetPrefetchZoomDelta() {
        mapHeroMap.prefetchZoomDelta = 2
        verify { nativeMapView.prefetchZoomDelta = 2 }
    }

    @Test
    fun testCameraForLatLngBounds() {
        val bounds = LatLngBounds.Builder().include(LatLng()).include(LatLng(1.0, 1.0)).build()
        mapHeroMap.setLatLngBoundsForCameraTarget(bounds)
        verify { nativeMapView.setLatLngBounds(bounds) }
    }

    @Test(expected = IllegalArgumentException::class)
    fun testAnimateCameraChecksDurationPositive() {
        mapHeroMap.animateCamera(CameraUpdateFactory.newLatLng(LatLng(30.0, 30.0)), 0, null)
    }

    @Test(expected = IllegalArgumentException::class)
    fun testEaseCameraChecksDurationPositive() {
        mapHeroMap.easeCamera(CameraUpdateFactory.newLatLng(LatLng(30.0, 30.0)), 0, null)
    }

    @Test
    fun testGetNativeMapPtr() {
        assertEquals(5, mapHeroMap.nativeMapPtr)
    }

    @Test
    fun testNativeMapIsNotCalledOnStateSave() {
        clearMocks(nativeMapView)
        mapHeroMap.onSaveInstanceState(mockk(relaxed = true))
        verify { nativeMapView wasNot Called }
    }

    @Test
    fun testCameraChangeDispatcherCleared() {
        mapHeroMap.onDestroy()
        verify { cameraChangeDispatcher.onDestroy() }
    }

    @Test
    fun testStyleClearedOnDestroy() {
        val style = mockk<Style>(relaxed = true)
        val builder = mockk<Style.Builder>(relaxed = true)
        every { builder.build(nativeMapView) } returns style
        mapHeroMap.setStyle(builder)

        mapHeroMap.onDestroy()
        verify(exactly = 1) { style.clear() }
    }

    @Test
    fun testStyleCallbackNotCalledWhenPreviousFailed() {
        val style = mockk<Style>(relaxed = true)
        val builder = mockk<Style.Builder>(relaxed = true)
        every { builder.build(nativeMapView) } returns style
        val onStyleLoadedListener = mockk<Style.OnStyleLoaded>(relaxed = true)

        mapHeroMap.setStyle(builder, onStyleLoadedListener)
        mapHeroMap.onFailLoadingStyle()
        mapHeroMap.setStyle(builder, onStyleLoadedListener)
        mapHeroMap.onFinishLoadingStyle()
        verify(exactly = 1) { onStyleLoadedListener.onStyleLoaded(style) }
    }

    @Test
    fun testStyleCallbackNotCalledWhenPreviousNotFinished() {
        // regression test for #14337
        val style = mockk<Style>(relaxed = true)
        val builder = mockk<Style.Builder>(relaxed = true)
        every { builder.build(nativeMapView) } returns style
        val onStyleLoadedListener = mockk<Style.OnStyleLoaded>(relaxed = true)

        mapHeroMap.setStyle(builder, onStyleLoadedListener)
        mapHeroMap.setStyle(builder, onStyleLoadedListener)
        mapHeroMap.onFinishLoadingStyle()
        verify(exactly = 1) { onStyleLoadedListener.onStyleLoaded(style) }
    }
}
