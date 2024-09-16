package org.maplibre.android.camera

import org.maplibre.android.maps.MapHeroMap

/**
 * Interface definition for camera updates.
 */
interface CameraUpdate {
    /**
     * Get the camera position from the camera update.
     *
     * @param mapHeroMap Map object to build the position from
     * @return the camera position from the implementing camera update
     */
    fun getCameraPosition(mapHeroMap: MapHeroMap): CameraPosition?
}
