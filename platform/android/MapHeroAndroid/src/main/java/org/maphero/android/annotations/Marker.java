package org.maphero.android.annotations;

import android.view.View;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import org.maphero.android.R;
import org.maphero.android.geometry.LatLng;
import org.maphero.android.maps.MapView;
import org.maphero.android.maps.MapHeroMap;

/**
 * Marker is an annotation that shows an icon image at a geographical location. The default marker
 * uses a provided icon. This icon can be customized using {@link IconFactory} to generate an
 * {@link Icon} using a provided image. Markers are added to the map by first giving a
 * {@link LatLng} and using {@link MapHeroMap#addMarker(MarkerOptions)}. The marker icon will be
 * centered at this position so it is common to add padding to the icon image before usage.
 * <p>
 * Markers are designed to be interactive. They receive click events by default, and are often used
 * with event listeners to bring up info windows. An {@link InfoWindow} is displayed by default when
 * either a title or snippet is provided.
 * </p>
 */
public class Marker extends Annotation {

  @Keep
  private LatLng position;
  private String snippet;
  @Nullable
  private Icon icon;
  //Redundantly stored for JNI access
  @Nullable
  @Keep
  private String iconId;
  private String title;

  @Nullable
  private InfoWindow infoWindow;
  private boolean infoWindowShown;

  private int topOffsetPixels;
  private int rightOffsetPixels;

  /**
   * Constructor
   */
  Marker() {
    super();
  }

  /**
   * Creates a instance of {@link Marker} using the builder of Marker.
   *
   * @param baseMarkerOptions The builder used to construct the Marker.
   */
  public Marker(BaseMarkerOptions baseMarkerOptions) {
    this(baseMarkerOptions.position, baseMarkerOptions.icon, baseMarkerOptions.title, baseMarkerOptions.snippet);
  }

  Marker(LatLng position, Icon icon, String title, String snippet) {
    this.position = position;
    this.title = title;
    this.snippet = snippet;
    setIcon(icon);
  }

  /**
   * Returns the position of the marker.
   *
   * @return A {@link LatLng} object specifying the marker's current position.
   */
  public LatLng getPosition() {
    return position;
  }

  /**
   * Gets the snippet of the marker.
   *
   * @return A string containing the marker's snippet.
   */
  public String getSnippet() {
    return snippet;
  }

  /**
   * Gets the snippet of the marker.
   *
   * @return A string containing the marker's snippet.
   */
  public String getTitle() {
    return title;
  }

  /**
   * Do not use this method, used internally by the SDK.
   */
  public void hideInfoWindow() {
    if (infoWindow != null) {
      infoWindow.close();
    }
    infoWindowShown = false;
  }

  /**
   * Do not use this method, used internally by the SDK.
   *
   * @return true if the infoWindow is shown
   */
  public boolean isInfoWindowShown() {
    return infoWindowShown;
  }

  /**
   * Sets the location of the marker.
   *
   * @param position A {@link LatLng} defining the marker position.
   */
  public void setPosition(LatLng position) {
    this.position = position;
    MapHeroMap map = getMapHeroMap();
    if (map != null) {
      map.updateMarker(this);
    }
  }

  /**
   * Sets the snippet of the marker.
   *
   * @param snippet A String used in the marker info window. If {@code null}, the snippet is
   *                cleared.
   */
  public void setSnippet(String snippet) {
    this.snippet = snippet;
    refreshInfoWindowContent();
  }

  /**
   * Sets the icon of the marker.
   *
   * @param icon The {@link Icon} to be used as Marker image
   */
  public void setIcon(@Nullable Icon icon) {
    this.icon = icon;
    this.iconId = icon != null ? icon.getId() : null;
    MapHeroMap map = getMapHeroMap();
    if (map != null) {
      map.updateMarker(this);
    }
  }

  /**
   * Gets the {@link Icon} currently used for the marker. If no Icon was set for the marker, the
   * default icon will be returned.
   *
   * @return The {@link Icon} the marker is using.
   */
  @Nullable
  public Icon getIcon() {
    return icon;
  }

  /**
   * Sets the title of the marker.
   *
   * @param title A String used in the marker info window. If {@code null}, the title is
   *              cleared.
   */
  public void setTitle(String title) {
    this.title = title;
    refreshInfoWindowContent();
  }

  /**
   * Gets the {@link InfoWindow} the marker is using. If the marker hasn't had an info window
   * defined, this will return {@code null}.
   *
   * @return The info window the marker is using.
   */
  @Nullable
  public InfoWindow getInfoWindow() {
    return infoWindow;
  }

  /**
   * Update only for default Marker's InfoWindow content for Title and Snippet
   */
  private void refreshInfoWindowContent() {
    if (isInfoWindowShown() && mapView != null && mapHeroMap != null && mapHeroMap.getInfoWindowAdapter() == null) {
      InfoWindow infoWindow = getInfoWindow(mapView);
      if (mapView.getContext() != null) {
        infoWindow.adaptDefaultMarker(this, mapHeroMap, mapView);
      }
      MapHeroMap map = getMapHeroMap();
      if (map != null) {
        map.updateMarker(this);
      }
      infoWindow.onContentUpdate();
    }
  }

  /**
   * Do not use this method, used internally by the SDK. Use {@link MapHeroMap#selectMarker(Marker)}
   * if you want to programmatically display the markers info window.
   *
   * @param mapHeroMap The hosting MapHeroMap.
   * @param mapView   The hosting map view.
   * @return The info window that was shown.
   */
  @Nullable
  public InfoWindow showInfoWindow(@NonNull MapHeroMap mapHeroMap, @NonNull MapView mapView) {
    setMapHeroMap(mapHeroMap);
    setMapView(mapView);
    MapHeroMap.InfoWindowAdapter infoWindowAdapter = getMapHeroMap().getInfoWindowAdapter();
    if (infoWindowAdapter != null) {
      // end developer is using a custom InfoWindowAdapter
      View content = infoWindowAdapter.getInfoWindow(this);
      if (content != null) {
        infoWindow = new InfoWindow(content, mapHeroMap);
        showInfoWindow(infoWindow, mapView);
        return infoWindow;
      }
    }

    InfoWindow infoWindow = getInfoWindow(mapView);
    if (mapView.getContext() != null) {
      infoWindow.adaptDefaultMarker(this, mapHeroMap, mapView);
    }
    return showInfoWindow(infoWindow, mapView);
  }

  @NonNull
  private InfoWindow showInfoWindow(InfoWindow iw, MapView mapView) {
    iw.open(mapView, this, getPosition(), rightOffsetPixels, topOffsetPixels);
    infoWindowShown = true;
    return iw;
  }

  @Nullable
  private InfoWindow getInfoWindow(@NonNull MapView mapView) {
    if (infoWindow == null && mapView.getContext() != null) {
      infoWindow = new InfoWindow(mapView, R.layout.maphero_infowindow_content, getMapHeroMap());
    }
    return infoWindow;
  }

  /**
   * Do not use this method, used internally by the SDK.
   *
   * @param topOffsetPixels the top offset pixels.
   */
  public void setTopOffsetPixels(int topOffsetPixels) {
    this.topOffsetPixels = topOffsetPixels;
  }

  /**
   * Do not use this method, used internally by the SDK.
   *
   * @param rightOffsetPixels the right offset pixels.
   */
  public void setRightOffsetPixels(int rightOffsetPixels) {
    this.rightOffsetPixels = rightOffsetPixels;
  }

  /**
   * Returns a String with the marker position.
   *
   * @return A String with the marker position.
   */
  @Override
  public String toString() {
    return "Marker [position[" + getPosition() + "]]";
  }
}
