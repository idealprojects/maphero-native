package org.maphero.android.location;

import android.animation.TypeEvaluator;

import androidx.annotation.NonNull;

import org.maphero.android.geometry.LatLng;

class MapHeroLatLngAnimator extends MapHeroAnimator<LatLng> {

  MapHeroLatLngAnimator(@NonNull LatLng[] values, @NonNull AnimationsValueChangeListener updateListener,
                        int maxAnimationFps) {
    super(values, updateListener, maxAnimationFps);
  }

  @NonNull
  @Override
  TypeEvaluator provideEvaluator() {
    return new LatLngEvaluator();
  }
}
