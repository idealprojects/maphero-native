package org.maphero.android.testapp.camera;

import org.maphero.android.camera.CameraUpdate;
import org.maphero.android.maps.MapHeroMap;

public class CameraAnimateTest extends CameraTest {
  @Override
  void executeCameraMovement(CameraUpdate cameraUpdate, MapHeroMap.CancelableCallback callback) {
    maplibreMap.animateCamera(cameraUpdate, callback);
  }
}