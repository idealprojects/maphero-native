package org.maplibre.android

import org.maplibre.android.testapp.MapHeroApplication

class InstrumentationApplication : MapHeroApplication() {
    fun initializeLeakCanary(): Boolean {
        // do not initialize leak canary during instrumentation tests
        return true
    }
}
