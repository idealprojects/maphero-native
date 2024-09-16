package org.maplibre.android.location;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.Size;

import org.maplibre.android.maps.MapHeroMap;

class MapHeroCameraAnimatorAdapter extends MapHeroFloatAnimator {

  MapHeroCameraAnimatorAdapter(@NonNull @Size(min = 2) Float[] values,
                               AnimationsValueChangeListener updateListener,
                               @Nullable MapHeroMap.CancelableCallback cancelableCallback) {
    super(values, updateListener, Integer.MAX_VALUE);
    addListener(new MapHeroAnimatorListener(cancelableCallback));
  }
}
