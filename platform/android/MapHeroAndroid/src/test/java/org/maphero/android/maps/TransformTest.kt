package org.maphero.android.maps

import android.os.Looper.getMainLooper
import org.maphero.android.camera.CameraPosition
import org.maphero.android.camera.CameraUpdateFactory
import org.maphero.android.geometry.LatLng
import io.mockk.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.shadows.ShadowLooper

@RunWith(RobolectricTestRunner::class)
class TransformTest {

    private lateinit var mapView: MapView
    private lateinit var nativeMapView: NativeMap
    private lateinit var transform: Transform
    private lateinit var cameraChangeDispatcher: CameraChangeDispatcher
    private lateinit var mainLooper: ShadowLooper

    @Before
    fun setup() {
        cameraChangeDispatcher = spyk()
        mapView = mockk()
        nativeMapView = mockk()
        mainLooper = shadowOf(getMainLooper())
        transform = Transform(mapView, nativeMapView, cameraChangeDispatcher)
        every { nativeMapView.isDestroyed } returns false
        every { nativeMapView.cameraPosition } returns CameraPosition.DEFAULT
        every { nativeMapView.cancelTransitions() } answers {}
        every { nativeMapView.jumpTo(any(), any(), any(), any(), any()) } answers {}
        every { nativeMapView.easeTo(any(), any(), any(), any(), any(), any(), any()) } answers {}
        every { nativeMapView.flyTo(any(), any(), any(), any(), any(), any()) } answers {}
        every { nativeMapView.minZoom = any() } answers {}
        every { nativeMapView.maxZoom = any() } answers {}
        every { nativeMapView.minPitch = any() } answers {}
        every { nativeMapView.maxPitch = any() } answers {}
    }

    @Test
    fun testMoveCamera() {
        val mapHeroMap = mockk<MapHeroMap>()
        every { mapHeroMap.cameraPosition } answers { CameraPosition.DEFAULT }

        val callback = mockk<MapHeroMap.CancelableCallback>()
        every { callback.onFinish() } answers {}

        val target = LatLng(1.0, 2.0)
        val expected = CameraPosition.Builder().target(target).build()
        val update = CameraUpdateFactory.newCameraPosition(expected)

        transform.cameraPosition
        every { nativeMapView.cameraPosition } returns expected
        transform.moveCamera(mapHeroMap, update, callback)

        mainLooper.idle()
        verify { cameraChangeDispatcher.onCameraMove() }
        verify { nativeMapView.jumpTo(target, -1.0, -1.0, -1.0, null) }
        verify { callback.onFinish() }
    }

    @Test
    fun testMoveCameraToSamePosition() {
        val mapHeroMap = mockk<MapHeroMap>()
        every { mapHeroMap.cameraPosition } answers { CameraPosition.DEFAULT }

        val callback = mockk<MapHeroMap.CancelableCallback>()
        every { callback.onFinish() } answers {}

        val expected = CameraPosition.DEFAULT
        val update = CameraUpdateFactory.newCameraPosition(expected)

        transform.moveCamera(mapHeroMap, update, null) // Initialize camera position
        transform.moveCamera(mapHeroMap, update, callback)

        verify(exactly = 1, verifyBlock = { nativeMapView.jumpTo(any(), any(), any(), any(), any()) })
        verify { callback.onFinish() }
    }

    @Test
    fun testEaseCamera() {
        val mapHeroMap = mockk<MapHeroMap>()
        every { mapHeroMap.cameraPosition } answers { CameraPosition.DEFAULT }

        every { mapView.addOnCameraDidChangeListener(any()) } answers { transform.onCameraDidChange(true) }
        every { mapView.removeOnCameraDidChangeListener(any()) } answers {}

        val callback = mockk<MapHeroMap.CancelableCallback>()
        every { callback.onFinish() } answers {}

        val target = LatLng(1.0, 2.0)
        val expected = CameraPosition.Builder().target(target).build()
        val update = CameraUpdateFactory.newCameraPosition(expected)

        transform.easeCamera(mapHeroMap, update, 100, false, callback)

        mainLooper.idle()
        verify { nativeMapView.easeTo(target, -1.0, -1.0, -1.0, null, 100, false) }
        verify { callback.onFinish() }
    }

    @Test
    fun testEaseCameraToSamePosition() {
        val mapHeroMap = mockk<MapHeroMap>()
        every { mapHeroMap.cameraPosition } answers { CameraPosition.DEFAULT }

        val callback = mockk<MapHeroMap.CancelableCallback>()
        every { callback.onFinish() } answers {}

        val expected = CameraPosition.DEFAULT
        val update = CameraUpdateFactory.newCameraPosition(expected)
        transform.moveCamera(mapHeroMap, update, null)

        transform.easeCamera(mapHeroMap, update, 100, false, callback)

        verify(exactly = 0, verifyBlock = { nativeMapView.easeTo(any(), any(), any(), any(), any(), any(), any()) })
        verify { callback.onFinish() }
    }

    @Test
    fun testAnimateCamera() {
        val mapHeroMap = mockk<MapHeroMap>()
        every { mapHeroMap.cameraPosition } answers { CameraPosition.DEFAULT }

        every { mapView.addOnCameraDidChangeListener(any()) } answers { transform.onCameraDidChange(true) }
        every { mapView.removeOnCameraDidChangeListener(any()) } answers {}

        val callback = mockk<MapHeroMap.CancelableCallback>()
        every { callback.onFinish() } answers {}

        val target = LatLng(1.0, 2.0)
        val expected = CameraPosition.Builder().target(target).build()
        val update = CameraUpdateFactory.newCameraPosition(expected)

        transform.animateCamera(mapHeroMap, update, 100, callback)

        mainLooper.idle()
        verify { nativeMapView.flyTo(target, -1.0, -1.0, -1.0, null, 100) }
        verify { callback.onFinish() }
    }

    @Test
    fun testAnimateCameraToSamePosition() {
        val mapHeroMap = mockk<MapHeroMap>()
        every { mapHeroMap.cameraPosition } answers { CameraPosition.DEFAULT }

        val callback = mockk<MapHeroMap.CancelableCallback>()
        every { callback.onFinish() } answers {}

        val expected = CameraPosition.DEFAULT
        val update = CameraUpdateFactory.newCameraPosition(expected)
        transform.moveCamera(mapHeroMap, update, null)

        transform.animateCamera(mapHeroMap, update, 100, callback)

        verify(exactly = 0, verifyBlock = { nativeMapView.flyTo(any(), any(), any(), any(), any(), any()) })
        verify { callback.onFinish() }
    }

    @Test
    fun testMinZoom() {
        transform.minZoom = 10.0
        verify { nativeMapView.minZoom = 10.0 }
    }

    @Test
    fun testMaxZoom() {
        transform.maxZoom = 10.0
        verify { nativeMapView.maxZoom = 10.0 }
    }

    @Test
    fun testMinPitch() {
        transform.minPitch = 10.0
        verify { nativeMapView.minPitch = 10.0 }
    }

    @Test
    fun testMaxPitch() {
        transform.maxPitch = 10.0
        verify { nativeMapView.maxPitch = 10.0 }
    }

    @Test
    fun testCancelNotInvokedFromOnFinish() {
        val slot = slot<MapView.OnCameraDidChangeListener>()
        every { mapView.addOnCameraDidChangeListener(capture(slot)) } answers { slot.captured.onCameraDidChange(true) }
        every { mapView.removeOnCameraDidChangeListener(any()) } answers {}
        // regression test for https://github.com/mapbox/mapbox-gl-native/issues/13735
        val mapHeroMap = mockk<MapHeroMap>()
        every { mapHeroMap.cameraPosition } answers { CameraPosition.DEFAULT }

        val target = LatLng(1.0, 2.0)
        val expected = CameraPosition.Builder().target(target).build()

        val callback = object : MapHeroMap.CancelableCallback {
            override fun onCancel() {
                throw IllegalStateException("onCancel shouldn't be called from onFinish")
            }

            override fun onFinish() {
                transform.animateCamera(mapHeroMap, CameraUpdateFactory.newCameraPosition(expected), 500, null)
            }
        }
        transform.animateCamera(mapHeroMap, CameraUpdateFactory.newCameraPosition(expected), 500, callback)
    }
}
