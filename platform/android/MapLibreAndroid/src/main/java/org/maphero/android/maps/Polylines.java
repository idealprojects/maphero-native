package org.maphero.android.maps;


import androidx.annotation.NonNull;

import org.maphero.android.annotations.Polyline;
import org.maphero.android.annotations.PolylineOptions;

import java.util.List;

/**
 * Interface that defines convenient methods for working with a {@link Polyline}'s collection.
 */
interface Polylines {
  Polyline addBy(@NonNull PolylineOptions polylineOptions, @NonNull MapHeroMap mapHeroMap);

  List<Polyline> addBy(@NonNull List<PolylineOptions> polylineOptionsList, @NonNull MapHeroMap mapHeroMap);

  void update(Polyline polyline);

  List<Polyline> obtainAll();
}
