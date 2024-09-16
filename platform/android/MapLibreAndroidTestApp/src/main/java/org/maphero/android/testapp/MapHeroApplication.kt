package org.maphero.android.testapp

import android.os.Build
import android.os.StrictMode
import android.os.StrictMode.ThreadPolicy
import android.os.StrictMode.VmPolicy
import android.text.TextUtils
import androidx.multidex.MultiDexApplication
import org.maphero.android.MapStrictMode
import org.maphero.android.MapHero
import org.maphero.android.log.Logger
import org.maphero.android.testapp.utils.ApiKeyUtils
import org.maphero.android.testapp.utils.TileLoadingMeasurementUtils
import org.maphero.android.testapp.utils.TimberLogger
import timber.log.Timber

/**
 * Application class of the test application.
 *
 *
 * Initialises components as LeakCanary, Strictmode, Timber and MapHero
 *
 */
open class MapHeroApplication : MultiDexApplication() {
    override fun onCreate() {
        super.onCreate()
        initializeLogger()
        initializeStrictMode()
        initializeMapbox()
    }

    private fun initializeLogger() {
        Logger.setLoggerDefinition(TimberLogger())
    }

    private fun initializeStrictMode() {
        StrictMode.setThreadPolicy(
            ThreadPolicy.Builder()
                .detectDiskReads()
                .detectDiskWrites()
                .detectNetwork()
                .penaltyLog()
                .build()
        )
        StrictMode.setVmPolicy(
            VmPolicy.Builder()
                .detectLeakedSqlLiteObjects()
                .penaltyLog()
                .penaltyDeath()
                .build()
        )
    }

    private fun initializeMapbox() {
        val apiKey = ApiKeyUtils.getApiKey(applicationContext)
        if (apiKey != null) {
            validateApiKey(apiKey)
        }
        MapHero.getInstance(applicationContext, apiKey)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            TileLoadingMeasurementUtils.setUpTileLoadingMeasurement()
        }
        MapStrictMode.setStrictModeEnabled(true)
    }

    companion object {
        private const val DEFAULT_API_KEY = "YOUR_API_KEY_GOES_HERE"
        private const val API_KEY_NOT_SET_MESSAGE =
            (
                "In order to run the Test App you need to set a valid " +
                    "API key. During development, you can set the MH_API_KEY environment variable for the SDK to " +
                    "automatically include it in the Test App. Otherwise, you can manually include it in the " +
                    "res/values/developer-config.xml file in the MapHeroAndroidTestApp folder."
                )

        private fun validateApiKey(apiKey: String) {
            if (TextUtils.isEmpty(apiKey) || apiKey == DEFAULT_API_KEY) {
                Timber.e(API_KEY_NOT_SET_MESSAGE)
            }
        }
    }
}
