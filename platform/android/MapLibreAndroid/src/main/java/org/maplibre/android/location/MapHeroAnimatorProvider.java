package org.maplibre.android.location;

import android.animation.ValueAnimator;
import android.view.animation.Interpolator;

import androidx.annotation.Nullable;

import org.maplibre.android.maps.MapHeroMap;
import org.maplibre.android.geometry.LatLng;

final class MapHeroAnimatorProvider {

  private static MapHeroAnimatorProvider INSTANCE;

  private MapHeroAnimatorProvider() {
    // private constructor
  }

  public static MapHeroAnimatorProvider getInstance() {
    if (INSTANCE == null) {
      INSTANCE = new MapHeroAnimatorProvider();
    }
    return INSTANCE;
  }

  MapHeroLatLngAnimator latLngAnimator(LatLng[] values, MapHeroAnimator.AnimationsValueChangeListener updateListener,
                                       int maxAnimationFps) {
    return new MapHeroLatLngAnimator(values, updateListener, maxAnimationFps);
  }

  MapHeroFloatAnimator floatAnimator(Float[] values, MapHeroAnimator.AnimationsValueChangeListener updateListener,
                                     int maxAnimationFps) {
    return new MapHeroFloatAnimator(values, updateListener, maxAnimationFps);
  }

  MapHeroCameraAnimatorAdapter cameraAnimator(Float[] values,
                                              MapHeroAnimator.AnimationsValueChangeListener updateListener,
                                              @Nullable MapHeroMap.CancelableCallback cancelableCallback) {
    return new MapHeroCameraAnimatorAdapter(values, updateListener, cancelableCallback);
  }

  MapHeroPaddingAnimator paddingAnimator(double[][] values,
                                         MapHeroAnimator.AnimationsValueChangeListener<double[]> updateListener,
                                         @Nullable MapHeroMap.CancelableCallback cancelableCallback) {
    return new MapHeroPaddingAnimator(values, updateListener, cancelableCallback);
  }

  /**
   * This animator is for the LocationComponent pulsing circle.
   *
   * @param updateListener the listener that is found in the {@link LocationAnimatorCoordinator}'s
   *                       listener array.
   * @param maxAnimationFps the max frames per second of the pulsing animation
   * @param pulseSingleDuration the number of milliseconds it takes for the animator to create
   *                            a single pulse.
   * @param pulseMaxRadius the max radius when the circle is finished with a single pulse.
   * @param pulseInterpolator the type of Android-system interpolator to use for
   *                                       the pulsing animation (linear, accelerate, bounce, etc.)
   * @return a built {@link PulsingLocationCircleAnimator} object.
   */
  PulsingLocationCircleAnimator pulsingCircleAnimator(MapHeroAnimator.AnimationsValueChangeListener updateListener,
                                                      int maxAnimationFps,
                                                      float pulseSingleDuration,
                                                      float pulseMaxRadius,
                                                      Interpolator pulseInterpolator) {
    PulsingLocationCircleAnimator pulsingLocationCircleAnimator =
        new PulsingLocationCircleAnimator(updateListener, maxAnimationFps, pulseMaxRadius);
    pulsingLocationCircleAnimator.setDuration((long) pulseSingleDuration);
    pulsingLocationCircleAnimator.setRepeatMode(ValueAnimator.RESTART);
    pulsingLocationCircleAnimator.setRepeatCount(ValueAnimator.INFINITE);
    pulsingLocationCircleAnimator.setInterpolator(pulseInterpolator);
    return pulsingLocationCircleAnimator;
  }
}
