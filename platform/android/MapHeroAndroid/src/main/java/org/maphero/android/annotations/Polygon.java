package org.maphero.android.annotations;

import android.graphics.Color;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;

import org.maphero.android.geometry.LatLng;
import org.maphero.android.maps.MapHeroMap;

import java.util.ArrayList;
import java.util.List;

/**
 * Polygon is a geometry annotation that's a closed loop of coordinates.
 */
public final class Polygon extends BasePointCollection {

  @Keep
  private int fillColor = Color.BLACK; // default fillColor is black
  @Keep
  private int strokeColor = Color.BLACK; // default strokeColor is black
  @Keep
  private List<List<LatLng>> holes;

  Polygon() {
    super();
    holes = new ArrayList<>();
  }

  /**
   * Get the color of the fill region of the polygon.
   *
   * @return The color of the fill.
   */
  public int getFillColor() {
    return fillColor;
  }

  /**
   * Get the color of the stroke of the polygon.
   *
   * @return The color of the stroke.
   */
  public int getStrokeColor() {
    return strokeColor;
  }

  /**
   * Returns a copy of the holes.
   *
   * @return A {@link List} of {@link List} of {@link LatLng} points making up the holes.
   */
  @NonNull
  public List<List<LatLng>> getHoles() {
    return new ArrayList<>(holes);
  }

  /**
   * Sets the color of the fill region of the polygon.
   *
   * @param color The color in ARGB format.
   */
  public void setFillColor(int color) {
    fillColor = color;
    update();
  }

  /**
   * Sets the color of the stroke of the polygon.
   *
   * @param color The color in ARGB format.
   */
  public void setStrokeColor(int color) {
    strokeColor = color;
    update();
  }

  /**
   * Sets the holes of this polygon. This method will take a copy of the holes, so further
   * mutations to holes will have no effect on this polygon.
   *
   * @param holes A {@link List} of {@link List} of {@link LatLng} points making up the holes.
   */
  public void setHoles(@NonNull List<? extends List<LatLng>> holes) {
    this.holes = new ArrayList<>(holes);
    update();
  }

  /**
   * Add a hole to the polygon.
   *
   * @param hole A {@link List} of {@link List} of {@link LatLng} points making up the hole to be added.
   */
  void addHole(List<LatLng> hole) {
    holes.add(hole);
    update();
  }

  @Override
  void update() {
    MapHeroMap mapHeroMap = getMapHeroMap();
    if (mapHeroMap != null) {
      mapHeroMap.updatePolygon(this);
    }
  }
}
