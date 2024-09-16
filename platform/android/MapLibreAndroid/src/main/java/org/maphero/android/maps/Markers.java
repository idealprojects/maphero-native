package org.maphero.android.maps;

import android.graphics.RectF;

import androidx.annotation.NonNull;

import org.maphero.android.annotations.BaseMarkerOptions;
import org.maphero.android.annotations.Marker;

import java.util.List;

/**
 * Interface that defines convenient methods for working with a {@link Marker}'s collection.
 */
interface Markers {
  Marker addBy(@NonNull BaseMarkerOptions markerOptions, @NonNull MapHeroMap mapHeroMap);

  List<Marker> addBy(@NonNull List<? extends BaseMarkerOptions> markerOptionsList, @NonNull MapHeroMap mapHeroMap);

  void update(@NonNull Marker updatedMarker, @NonNull MapHeroMap mapHeroMap);

  List<Marker> obtainAll();

  @NonNull
  List<Marker> obtainAllIn(@NonNull RectF rectangle);

  void reload();
}
