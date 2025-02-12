package org.maphero.android.testapp.styles

import org.maphero.android.maps.Style

object TestStyles {
    val VERSATILES = "https://tiles.versatiles.org/assets/styles/colorful.json"

    val AMERICANA = "https://americanamap.org/style.json"

    fun getPredefinedStyleWithFallback(name: String): String {
        try {
            val style = Style.getPredefinedStyle(name)
            return style
        } catch (e: Exception) {
            return VERSATILES
        }
    }
}