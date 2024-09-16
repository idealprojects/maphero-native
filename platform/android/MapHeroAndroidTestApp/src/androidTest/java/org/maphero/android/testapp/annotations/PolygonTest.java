package org.maphero.android.testapp.annotations;

import android.graphics.Color;

import org.maphero.android.annotations.Polygon;
import org.maphero.android.annotations.PolygonOptions;
import org.maphero.android.geometry.LatLng;
import org.maphero.android.testapp.activity.EspressoTest;

import org.junit.Ignore;
import org.junit.Test;

import static org.maphero.android.testapp.action.MapLibreMapAction.invoke;
import static org.junit.Assert.assertEquals;

public class PolygonTest extends EspressoTest {

  @Test
  @Ignore
  public void addPolygonTest() {
    validateTestSetup();
    invoke(maplibreMap, (uiController, maplibreMap) -> {
      LatLng latLngOne = new LatLng();
      LatLng latLngTwo = new LatLng(1, 0);
      LatLng latLngThree = new LatLng(1, 1);

      assertEquals("Polygons should be empty", 0, maplibreMap.getPolygons().size());

      final PolygonOptions options = new PolygonOptions();
      options.strokeColor(Color.BLUE);
      options.fillColor(Color.RED);
      options.add(latLngOne);
      options.add(latLngTwo);
      options.add(latLngThree);
      Polygon polygon = maplibreMap.addPolygon(options);

      assertEquals("Polygons should be 1", 1, maplibreMap.getPolygons().size());
      assertEquals("Polygon id should be 0", 0, polygon.getId());
      assertEquals("Polygon points size should match", 3, polygon.getPoints().size());
      assertEquals("Polygon stroke color should match", Color.BLUE, polygon.getStrokeColor());
      assertEquals("Polygon target should match", Color.RED, polygon.getFillColor());
      maplibreMap.clear();
      assertEquals("Polygons should be empty", 0, maplibreMap.getPolygons().size());
    });
  }
}
