package org.maplibre.android.testapp.camera;

import org.maplibre.android.camera.CameraUpdate;
import org.maplibre.android.maps.MapHeroMap;

public class CameraAnimateTest extends CameraTest {
  @Override
  void executeCameraMovement(CameraUpdate cameraUpdate, MapHeroMap.CancelableCallback callback) {
    maplibreMap.animateCamera(cameraUpdate, callback);
  }
}