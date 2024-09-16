package org.maphero.android.location;

import android.graphics.Bitmap;

import androidx.annotation.Nullable;

import org.maphero.android.location.modes.RenderMode;
import org.maphero.android.maps.Style;
import org.maphero.android.style.expressions.Expression;
import org.maphero.android.geometry.LatLng;

interface LocationLayerRenderer {
  void initializeComponents(Style style);

  void addLayers(LocationComponentPositionManager positionManager);

  void removeLayers();

  void hide();

  void cameraTiltUpdated(double tilt);

  void cameraBearingUpdated(double bearing);

  void show(@RenderMode.Mode int renderMode, boolean isStale);

  void styleAccuracy(float accuracyAlpha, int accuracyColor);

  void setLatLng(LatLng latLng);

  void setGpsBearing(Float gpsBearing);

  void setCompassBearing(Float compassBearing);

  void setAccuracyRadius(Float accuracy);

  void styleScaling(Expression scaleExpression);

  void setLocationStale(boolean isStale, int renderMode);

  void adjustPulsingCircleLayerVisibility(boolean visible);

  void stylePulsingCircle(LocationComponentOptions options);

  void updatePulsingUi(float radius, @Nullable Float opacity);

  void updateIconIds(String foregroundIconString, String foregroundStaleIconString, String backgroundIconString,
                     String backgroundStaleIconString, String bearingIconString);

  void addBitmaps(@RenderMode.Mode int renderMode, @Nullable Bitmap shadowBitmap, Bitmap backgroundBitmap,
                  Bitmap backgroundStaleBitmap, Bitmap bearingBitmap,
                  Bitmap foregroundBitmap, Bitmap foregroundStaleBitmap);
}
