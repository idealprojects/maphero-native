package org.maphero.android.maps;

import android.text.TextUtils;

import androidx.annotation.Nullable;

import org.maphero.android.annotations.InfoWindow;
import org.maphero.android.annotations.Marker;

import java.util.ArrayList;
import java.util.List;

/**
 * Responsible for managing InfoWindows shown on the Map.
 * <p>
 * Maintains a {@link List} of opened {@link InfoWindow} and tracks configurations as
 * allowConcurrentMultipleInfoWindows which allows to have multiple {@link InfoWindow} open at the
 * same time. Responsible for managing listeners as
 * {@link MapHeroMap.OnInfoWindowClickListener} and
 * {@link MapHeroMap.OnInfoWindowLongClickListener}.
 * </p>
 */
class InfoWindowManager {

  private final List<InfoWindow> infoWindows = new ArrayList<>();

  @Nullable
  private MapHeroMap.InfoWindowAdapter infoWindowAdapter;
  private boolean allowConcurrentMultipleInfoWindows;

  @Nullable
  private MapHeroMap.OnInfoWindowClickListener onInfoWindowClickListener;
  @Nullable
  private MapHeroMap.OnInfoWindowLongClickListener onInfoWindowLongClickListener;
  @Nullable
  private MapHeroMap.OnInfoWindowCloseListener onInfoWindowCloseListener;

  void update() {
    if (!infoWindows.isEmpty()) {
      for (InfoWindow infoWindow : infoWindows) {
        infoWindow.update();
      }
    }
  }

  void setInfoWindowAdapter(@Nullable MapHeroMap.InfoWindowAdapter infoWindowAdapter) {
    this.infoWindowAdapter = infoWindowAdapter;
  }

  @Nullable
  MapHeroMap.InfoWindowAdapter getInfoWindowAdapter() {
    return infoWindowAdapter;
  }

  void setAllowConcurrentMultipleOpenInfoWindows(boolean allow) {
    allowConcurrentMultipleInfoWindows = allow;
  }

  boolean isAllowConcurrentMultipleOpenInfoWindows() {
    return allowConcurrentMultipleInfoWindows;
  }

  boolean isInfoWindowValidForMarker(@Nullable Marker marker) {
    return marker != null && (!TextUtils.isEmpty(marker.getTitle()) || !TextUtils.isEmpty(marker.getSnippet()));
  }

  void setOnInfoWindowClickListener(@Nullable MapHeroMap.OnInfoWindowClickListener listener) {
    onInfoWindowClickListener = listener;
  }

  @Nullable
  MapHeroMap.OnInfoWindowClickListener getOnInfoWindowClickListener() {
    return onInfoWindowClickListener;
  }

  void setOnInfoWindowLongClickListener(@Nullable MapHeroMap.OnInfoWindowLongClickListener listener) {
    onInfoWindowLongClickListener = listener;
  }

  @Nullable
  MapHeroMap.OnInfoWindowLongClickListener getOnInfoWindowLongClickListener() {
    return onInfoWindowLongClickListener;
  }

  void setOnInfoWindowCloseListener(@Nullable MapHeroMap.OnInfoWindowCloseListener listener) {
    onInfoWindowCloseListener = listener;
  }

  @Nullable
  MapHeroMap.OnInfoWindowCloseListener getOnInfoWindowCloseListener() {
    return onInfoWindowCloseListener;
  }

  public void add(InfoWindow infoWindow) {
    infoWindows.add(infoWindow);
  }
}
