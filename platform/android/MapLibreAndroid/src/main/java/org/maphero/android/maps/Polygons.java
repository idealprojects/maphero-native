package org.maphero.android.maps;


import androidx.annotation.NonNull;

import org.maphero.android.annotations.Polygon;
import org.maphero.android.annotations.PolygonOptions;

import java.util.List;

/**
 * Interface that defines convenient methods for working with a {@link Polygon}'s collection.
 */
interface Polygons {
  Polygon addBy(@NonNull PolygonOptions polygonOptions, @NonNull MapHeroMap mapHeroMap);

  List<Polygon> addBy(@NonNull List<PolygonOptions> polygonOptionsList, @NonNull MapHeroMap mapHeroMap);

  void update(Polygon polygon);

  List<Polygon> obtainAll();
}
