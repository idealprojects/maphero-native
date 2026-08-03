package org.maphero.android.testapp.activity.render

import android.content.Context
import org.maphero.android.snapshotter.MapSnapshot
import org.maphero.android.snapshotter.MapSnapshotter

class RenderTestSnapshotter internal constructor(context: Context, options: Options) :
    MapSnapshotter(context, options) {
    override fun addOverlay(mapSnapshot: MapSnapshot) {
        // don't add an overlay
    }
}
