package org.maphero.android.location;

import android.animation.Animator;
import android.animation.AnimatorSet;
import android.view.animation.Interpolator;

import androidx.annotation.NonNull;

import java.util.List;

class MapHeroAnimatorSetProvider {
  private static MapHeroAnimatorSetProvider instance;

  private MapHeroAnimatorSetProvider() {
    // private constructor
  }

  static MapHeroAnimatorSetProvider getInstance() {
    if (instance == null) {
      instance = new MapHeroAnimatorSetProvider();
    }
    return instance;
  }

  void startAnimation(@NonNull List<Animator> animators, @NonNull Interpolator interpolator,
                      long duration) {
    AnimatorSet locationAnimatorSet = new AnimatorSet();
    locationAnimatorSet.playTogether(animators);
    locationAnimatorSet.setInterpolator(interpolator);
    locationAnimatorSet.setDuration(duration);
    locationAnimatorSet.start();
  }
}
