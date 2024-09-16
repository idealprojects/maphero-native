package org.maphero.android.annotations

import android.graphics.PointF
import org.maphero.android.geometry.LatLng
import org.maphero.android.maps.MapView
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.Projection
import org.junit.Assert
import org.junit.Test
import org.mockito.InjectMocks
import org.mockito.Mockito

class InfoWindowTest {
    @InjectMocks
    var mMapView = Mockito.mock(MapView::class.java)

    @InjectMocks
    var mMapHeroMap = Mockito.mock(MapHeroMap::class.java)

    @Test
    fun testSanity() {
        val infoWindow = InfoWindow(mMapView, mMapHeroMap)
        Assert.assertNotNull("infoWindow should exist", infoWindow)
    }

    @Test
    fun testBoundMarker() {
        val markerOptions = MarkerOptions()
        val marker = markerOptions.position(LatLng()).marker
        val infoWindow = InfoWindow(mMapView, mMapHeroMap).setBoundMarker(marker)
        Assert.assertEquals("marker should match", marker, infoWindow.boundMarker)
    }

    @Test
    fun testClose() {
        val infoWindow = InfoWindow(mMapView, mMapHeroMap)
        infoWindow.close()
        Assert.assertEquals("infowindow should not be visible", false, infoWindow.isVisible)
    }

    @Test
    fun testOpen() {
        val latLng = LatLng(0.0, 0.0)
        val projection = Mockito.mock(
            Projection::class.java
        )
        Mockito.`when`(mMapHeroMap.projection).thenReturn(projection)
        Mockito.`when`(projection.toScreenLocation(latLng)).thenReturn(PointF(0f, 0f))
        val infoWindow = InfoWindow(mMapView, mMapHeroMap)
        infoWindow.open(mMapView, MarkerOptions().position(LatLng()).marker, latLng, 0, 0)
        Assert.assertEquals("infowindow should not be visible", true, infoWindow.isVisible)
    }

    @Test
    fun testOpenClose() {
        val latLng = LatLng(0.0, 0.0)
        val projection = Mockito.mock(
            Projection::class.java
        )
        Mockito.`when`(mMapHeroMap.projection).thenReturn(projection)
        Mockito.`when`(projection.toScreenLocation(latLng)).thenReturn(PointF(0f, 0f))
        val infoWindow = InfoWindow(mMapView, mMapHeroMap)
        infoWindow.open(mMapView, MarkerOptions().position(LatLng()).marker, latLng, 0, 0)
        infoWindow.close()
        Assert.assertEquals("infowindow should not be visible", false, infoWindow.isVisible)
    }

    @Test
    fun testUpdate() {
        val latLng = LatLng(0.0, 0.0)
        val projection = Mockito.mock(
            Projection::class.java
        )
        Mockito.`when`(mMapHeroMap.projection).thenReturn(projection)
        Mockito.`when`(projection.toScreenLocation(latLng)).thenReturn(PointF(0f, 0f))
        val infoWindow = InfoWindow(mMapView, mMapHeroMap)
        infoWindow.open(mMapView, MarkerOptions().position(latLng).marker, latLng, 0, 0)
        infoWindow.update()
    }
}
