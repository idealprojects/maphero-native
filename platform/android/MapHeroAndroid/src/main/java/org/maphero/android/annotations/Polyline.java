package org.maphero.android.annotations;

import android.graphics.Color;

import androidx.annotation.Keep;

import org.maphero.android.maps.MapHeroMap;

/**
 * Polyline is a geometry feature with an unclosed list of coordinates drawn as a line
 */
public final class Polyline extends BasePointCollection {

  @Keep
  private int color = Color.BLACK; // default color is black
  @Keep
  private float width = 10; // As specified by Google API Docs (in pixels)

  Polyline() {
    super();
  }

  /**
   * Gets the color of this polyline.
   *
   * @return The color in ARGB format.
   */
  public int getColor() {
    return color;
  }

  /**
   * Gets the width of this polyline.
   *
   * @return The width in screen pixels.
   */
  public float getWidth() {
    return width;
  }

  /**
   * Sets the color of the polyline.
   *
   * @param color - the color in ARGB format
   */
  public void setColor(int color) {
    this.color = color;
    update();
  }

  /**
   * Sets the width of the polyline.
   *
   * @param width in pixels
   */
  public void setWidth(float width) {
    this.width = width;
    update();
  }

  @Override
  void update() {
    MapHeroMap mapHeroMap = getMapHeroMap();
    if (mapHeroMap != null) {
      mapHeroMap.updatePolyline(this);
    }
  }
}
