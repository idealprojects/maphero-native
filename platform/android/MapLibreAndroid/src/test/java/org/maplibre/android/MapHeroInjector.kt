package org.maplibre.android

import android.content.Context
import org.maplibre.android.util.TileServerOptions

object MapHeroInjector {
    private const val FIELD_INSTANCE = "INSTANCE"
    @JvmStatic
    fun inject(context: Context, apiKey: String,
               options: TileServerOptions) {
        val mapHero = MapHero(context, apiKey, options)
        try {
            val instance = MapHero::class.java.getDeclaredField(FIELD_INSTANCE)
            instance.isAccessible = true
            instance[mapHero] = mapHero
        } catch (exception: Exception) {
            throw AssertionError()
        }
    }

    @JvmStatic
    fun clear() {
        try {
            val field = MapHero::class.java.getDeclaredField(FIELD_INSTANCE)
            field.isAccessible = true
            field[field] = null
        } catch (exception: Exception) {
            throw AssertionError()
        }
    }
}