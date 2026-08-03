package org.maphero.android.style.layers;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;

/**
 * A style layer that renders glTF (.glb) building models inside the map's own
 * render pass — true map geometry, depth-tested against 3D layers and controlled
 * by the standard minzoom/maxzoom/visibility mechanisms.
 *
 * <p>Models are supplied as a GeoJSON FeatureCollection of Point features:
 * the geometry is the anchor, and the properties are:
 * <ul>
 *   <li>{@code path} (string, required) — absolute filesystem path or file:// URI of the .glb</li>
 *   <li>{@code heading} (number, optional) — rotation around the up axis, in degrees</li>
 *   <li>{@code size} (number, optional) — largest horizontal extent the model is
 *       auto-fitted to, in meters (default 180)</li>
 * </ul>
 *
 * <pre>{@code
 * Model3DLayer layer = new Model3DLayer("buildings-3d");
 * layer.setData(featureCollectionJson);
 * layer.setMaxZoom(16.5f);
 * style.addLayer(layer);
 * }</pre>
 */
@Keep
public class Model3DLayer extends Layer {

  public Model3DLayer(@NonNull String layerId) {
    initialize(layerId);
  }

  /**
   * Replaces the rendered models with the Point features of the given GeoJSON
   * FeatureCollection (may also be a single Feature).
   */
  public void setData(@NonNull String featureCollectionJson) {
    checkThread();
    nativeSetData(featureCollectionJson);
  }

  @Keep
  Model3DLayer(long nativePtr) {
    super(nativePtr);
  }

  @Keep
  protected native void initialize(String layerId);

  @Keep
  private native void nativeSetData(String json);

  @Override
  @Keep
  protected native void finalize() throws Throwable;

}
