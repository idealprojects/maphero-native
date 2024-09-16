package org.maphero.android

import org.maphero.android.testapp.MapHeroApplication

class InstrumentationApplication : MapHeroApplication() {
    fun initializeLeakCanary(): Boolean {
        // do not initialize leak canary during instrumentation tests
        return true
    }
}
