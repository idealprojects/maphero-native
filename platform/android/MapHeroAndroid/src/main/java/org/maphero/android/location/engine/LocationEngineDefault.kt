package org.maphero.android.location.engine

import android.content.Context

object LocationEngineDefault {
    /**
     * Returns the default `LocationEngine`.
     */
    fun getDefaultLocationEngine(context: Context): LocationEngine {
        return LocationEngineProxy(
            MapHeroFusedLocationEngineImpl(
                context.applicationContext
            )
        )
    }
}
