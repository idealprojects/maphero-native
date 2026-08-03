package org.maphero.android.camera

import org.maphero.android.maps.MapHeroMap

/**
 * Interface definition for camera updates.
 */
interface CameraUpdate {
    /**
     * Get the camera position from the camera update.
     *
     * @param maplibreMap Map object to build the position from
     * @return the camera position from the implementing camera update
     */
    fun getCameraPosition(maplibreMap: MapHeroMap): CameraPosition?
}
