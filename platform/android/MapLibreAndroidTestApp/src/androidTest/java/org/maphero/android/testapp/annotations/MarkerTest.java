package org.maphero.android.testapp.annotations;

import org.maphero.android.annotations.Marker;
import org.maphero.android.annotations.MarkerOptions;
import org.maphero.android.geometry.LatLng;
import org.maphero.android.testapp.action.MapLibreMapAction;
import org.maphero.android.testapp.activity.EspressoTest;
import org.maphero.android.testapp.utils.TestConstants;

import org.junit.Ignore;
import org.junit.Test;

import static androidx.test.espresso.Espresso.onView;
import static androidx.test.espresso.assertion.ViewAssertions.matches;
import static androidx.test.espresso.matcher.ViewMatchers.isDisplayed;
import static androidx.test.espresso.matcher.ViewMatchers.withText;
import static org.maphero.android.testapp.action.MapLibreMapAction.invoke;
import static org.junit.Assert.assertEquals;

public class MarkerTest extends EspressoTest {

  private Marker marker;

  @Test
  @Ignore
  public void addMarkerTest() {
    validateTestSetup();
    MapLibreMapAction.invoke(maplibreMap, (uiController, maplibreMap) -> {
      assertEquals("Markers should be empty", 0, maplibreMap.getMarkers().size());

      MarkerOptions options = new MarkerOptions();
      options.setPosition(new LatLng());
      options.setSnippet(TestConstants.TEXT_MARKER_SNIPPET);
      options.setTitle(TestConstants.TEXT_MARKER_TITLE);
      marker = maplibreMap.addMarker(options);

      assertEquals("Markers size should be 1, ", 1, maplibreMap.getMarkers().size());
      assertEquals("Marker id should be 0", 0, marker.getId());
      assertEquals("Marker target should match", new LatLng(), marker.getPosition());
      assertEquals("Marker snippet should match", TestConstants.TEXT_MARKER_SNIPPET, marker.getSnippet());
      assertEquals("Marker target should match", TestConstants.TEXT_MARKER_TITLE, marker.getTitle());
      maplibreMap.clear();
      assertEquals("Markers should be empty", 0, maplibreMap.getMarkers().size());
    });
  }

  @Test
  @Ignore
  public void showInfoWindowTest() {
    validateTestSetup();
    invoke(maplibreMap, (uiController, maplibreMap) -> {
      final MarkerOptions options = new MarkerOptions();
      options.setPosition(new LatLng());
      options.setSnippet(TestConstants.TEXT_MARKER_SNIPPET);
      options.setTitle(TestConstants.TEXT_MARKER_TITLE);
      marker = maplibreMap.addMarker(options);
      maplibreMap.selectMarker(marker);
    });
    onView(withText(TestConstants.TEXT_MARKER_TITLE)).check(matches(isDisplayed()));
    onView(withText(TestConstants.TEXT_MARKER_SNIPPET)).check(matches(isDisplayed()));
  }

}
