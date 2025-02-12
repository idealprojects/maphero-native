package org.maphero.android.location

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import org.maphero.android.maps.MapHeroMap

internal class MapHeroAnimatorListener(cancelableCallback: MapHeroMap.CancelableCallback?) :
    AnimatorListenerAdapter() {
    private val cancelableCallback: MapHeroMap.CancelableCallback?

    init {
        this.cancelableCallback = cancelableCallback
    }

    override fun onAnimationCancel(animation: Animator) {
        cancelableCallback?.onCancel()
    }

    override fun onAnimationEnd(animation: Animator) {
        cancelableCallback?.onFinish()
    }
}