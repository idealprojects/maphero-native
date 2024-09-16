package org.maphero.android.testapp.utils

import android.widget.TextView
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.MapHeroMap.OnCameraIdleListener
import org.maphero.android.testapp.R

class IdleZoomListener(private val mapHeroMap: MapHeroMap, private val textView: TextView) :
    OnCameraIdleListener {
    override fun onCameraIdle() {
        val context = textView.context
        val position = mapHeroMap.cameraPosition
        textView.text = String.format(context.getString(R.string.debug_zoom), position.zoom)
    }
}
