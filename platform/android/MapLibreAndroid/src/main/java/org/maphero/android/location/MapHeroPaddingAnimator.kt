package org.maphero.android.location

import android.animation.TypeEvaluator
import androidx.annotation.Size
import org.maphero.android.maps.MapHeroMap.CancelableCallback

class MapHeroPaddingAnimator internal constructor(
    @Size(min = 2) values: Array<DoubleArray>,
    updateListener: AnimationsValueChangeListener<DoubleArray>,
    cancelableCallback: CancelableCallback?
) :
    MapHeroAnimator<DoubleArray>(values, updateListener, Int.MAX_VALUE) {
    init {
        addListener(MapHeroAnimatorListener(cancelableCallback))
    }

    public override fun provideEvaluator(): TypeEvaluator<DoubleArray> {
        return PaddingEvaluator()
    }
}