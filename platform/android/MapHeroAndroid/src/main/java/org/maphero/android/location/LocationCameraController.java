package org.maphero.android.location;

import android.content.Context;
import android.graphics.PointF;
import android.graphics.RectF;
import android.location.Location;
import android.view.MotionEvent;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;

import org.maplibre.android.gestures.AndroidGesturesManager;
import org.maplibre.android.gestures.MoveGestureDetector;
import org.maplibre.android.gestures.RotateGestureDetector;
import org.maphero.android.location.modes.CameraMode;
import org.maphero.android.maps.MapHeroMap;
import org.maphero.android.maps.Transform;

import java.util.HashSet;
import java.util.Set;

import static org.maphero.android.location.LocationComponentConstants.TRANSITION_ANIMATION_DURATION_MS;

import org.maphero.android.camera.CameraPosition;
import org.maphero.android.camera.CameraUpdate;
import org.maphero.android.camera.CameraUpdateFactory;
import org.maphero.android.geometry.LatLng;

final class LocationCameraController {

  @CameraMode.Mode
  private int cameraMode;

  private final MapHeroMap mapHeroMap;
  private final Transform transform;
  private final OnCameraTrackingChangedListener internalCameraTrackingChangedListener;
  private LocationComponentOptions options;

  private final MoveGestureDetector moveGestureDetector;
  private final OnCameraMoveInvalidateListener onCameraMoveInvalidateListener;

  private final AndroidGesturesManager initialGesturesManager;
  private final AndroidGesturesManager internalGesturesManager;

  private boolean isTransitioning;
  private LatLng lastLocation;
  private boolean isEnabled;

  LocationCameraController(
    Context context,
    MapHeroMap mapHeroMap,
    Transform transform,
    OnCameraTrackingChangedListener internalCameraTrackingChangedListener,
    @NonNull LocationComponentOptions options,
    OnCameraMoveInvalidateListener onCameraMoveInvalidateListener) {
    this.mapHeroMap = mapHeroMap;
    this.transform = transform;

    initialGesturesManager = mapHeroMap.getGesturesManager();
    internalGesturesManager = new LocationGesturesManager(context);
    moveGestureDetector = internalGesturesManager.getMoveGestureDetector();
    mapHeroMap.addOnRotateListener(onRotateListener);
    mapHeroMap.addOnFlingListener(onFlingListener);
    mapHeroMap.addOnMoveListener(onMoveListener);
    mapHeroMap.addOnCameraMoveListener(onCameraMoveListener);
    this.internalCameraTrackingChangedListener = internalCameraTrackingChangedListener;
    this.onCameraMoveInvalidateListener = onCameraMoveInvalidateListener;
    initializeOptions(options);
  }

  // Package private for testing purposes
  LocationCameraController(MapHeroMap mapHeroMap,
                           Transform transform,
                           MoveGestureDetector moveGestureDetector,
                           OnCameraTrackingChangedListener internalCameraTrackingChangedListener,
                           OnCameraMoveInvalidateListener onCameraMoveInvalidateListener,
                           AndroidGesturesManager initialGesturesManager,
                           AndroidGesturesManager internalGesturesManager) {
    this.mapHeroMap = mapHeroMap;
    mapHeroMap.addOnCameraMoveListener(onCameraMoveListener);
    this.transform = transform;
    this.moveGestureDetector = moveGestureDetector;
    this.internalCameraTrackingChangedListener = internalCameraTrackingChangedListener;
    this.onCameraMoveInvalidateListener = onCameraMoveInvalidateListener;
    this.internalGesturesManager = internalGesturesManager;
    this.initialGesturesManager = initialGesturesManager;
  }

  void initializeOptions(LocationComponentOptions options) {
    this.options = options;
    if (options.trackingGesturesManagement()) {
      if (mapHeroMap.getGesturesManager() != internalGesturesManager) {
        mapHeroMap.setGesturesManager(internalGesturesManager, true, true);
      }
      adjustGesturesThresholds();
    } else if (mapHeroMap.getGesturesManager() != initialGesturesManager) {
      mapHeroMap.setGesturesManager(initialGesturesManager, true, true);
    }
  }

  void setCameraMode(@CameraMode.Mode int cameraMode) {
    setCameraMode(cameraMode, null, TRANSITION_ANIMATION_DURATION_MS, null, null, null, null);
  }

  void setCameraMode(@CameraMode.Mode final int cameraMode, @Nullable Location lastLocation,
                     long transitionDuration,
                     @Nullable Double zoom, @Nullable Double bearing, @Nullable Double tilt,
                     @Nullable OnLocationCameraTransitionListener internalTransitionListener) {
    if (this.cameraMode == cameraMode) {
      if (internalTransitionListener != null) {
        internalTransitionListener.onLocationCameraTransitionFinished(cameraMode);
      }
      return;
    }

    final boolean wasTracking = isLocationTracking();
    this.cameraMode = cameraMode;

    if (cameraMode != CameraMode.NONE) {
      mapHeroMap.cancelTransitions();
    }

    adjustGesturesThresholds();
    notifyCameraTrackingChangeListener(wasTracking);
    transitionToCurrentLocation(
      wasTracking, lastLocation, transitionDuration, zoom, bearing, tilt, internalTransitionListener);
  }

  /**
   * Initiates a camera animation to the current location if location tracking was engaged.
   * Notifies an internal listener when the transition's finished to invalidate animators and notify external listeners.
   */
  private void transitionToCurrentLocation(boolean wasTracking, Location lastLocation,
                                           long transitionDuration,
                                           Double zoom, Double bearing, Double tilt,
                                           final OnLocationCameraTransitionListener internalTransitionListener) {
    if (!wasTracking && isLocationTracking() && lastLocation != null && isEnabled) {
      isTransitioning = true;
      LatLng target = new LatLng(lastLocation);

      CameraPosition.Builder builder = new CameraPosition.Builder().target(target);
      if (zoom != null) {
        builder.zoom(zoom);
      }
      if (tilt != null) {
        builder.tilt(tilt);
      }
      if (bearing != null) {
        builder.bearing(bearing);
      } else {
        if (isLocationBearingTracking()) {
          builder.bearing(cameraMode == CameraMode.TRACKING_GPS_NORTH ? 0 : lastLocation.getBearing());
        }
      }

      CameraUpdate update = CameraUpdateFactory.newCameraPosition(builder.build());
      MapHeroMap.CancelableCallback callback = new MapHeroMap.CancelableCallback() {
        @Override
        public void onCancel() {
          isTransitioning = false;
          if (internalTransitionListener != null) {
            internalTransitionListener.onLocationCameraTransitionCanceled(cameraMode);
          }
        }

        @Override
        public void onFinish() {
          isTransitioning = false;
          if (internalTransitionListener != null) {
            internalTransitionListener.onLocationCameraTransitionFinished(cameraMode);
          }
        }
      };

      CameraPosition currentPosition = mapHeroMap.getCameraPosition();
      if (Utils.immediateAnimation(mapHeroMap.getProjection(), currentPosition.target, target)) {
        transform.moveCamera(
                mapHeroMap,
          update,
          callback);
      } else {
        transform.animateCamera(
                mapHeroMap,
          update,
          (int) transitionDuration,
          callback);
      }
    } else {
      if (internalTransitionListener != null) {
        internalTransitionListener.onLocationCameraTransitionFinished(cameraMode);
      }
    }
  }

  int getCameraMode() {
    return cameraMode;
  }

  private void setBearing(float bearing) {
    if (isTransitioning) {
      return;
    }

    transform.moveCamera(mapHeroMap, CameraUpdateFactory.bearingTo(bearing), null);
    onCameraMoveInvalidateListener.onInvalidateCameraMove();
  }

  private void setLatLng(@NonNull LatLng latLng) {
    if (isTransitioning) {
      return;
    }
    lastLocation = latLng;
    transform.moveCamera(mapHeroMap, CameraUpdateFactory.newLatLng(latLng), null);
    onCameraMoveInvalidateListener.onInvalidateCameraMove();
  }

  private void setZoom(float zoom) {
    if (isTransitioning) {
      return;
    }

    transform.moveCamera(mapHeroMap, CameraUpdateFactory.zoomTo(zoom), null);
    onCameraMoveInvalidateListener.onInvalidateCameraMove();
  }

  private void setPadding(double[] padding) {
    if (isTransitioning) {
      return;
    }

    transform.moveCamera(mapHeroMap, CameraUpdateFactory.paddingTo(padding), null);
    onCameraMoveInvalidateListener.onInvalidateCameraMove();
  }

  private void setTilt(float tilt) {
    if (isTransitioning) {
      return;
    }

    transform.moveCamera(mapHeroMap, CameraUpdateFactory.tiltTo(tilt), null);
    onCameraMoveInvalidateListener.onInvalidateCameraMove();
  }

  private final MapHeroAnimator.AnimationsValueChangeListener<LatLng> latLngValueListener =
    new MapHeroAnimator.AnimationsValueChangeListener<LatLng>() {
      @Override
      public void onNewAnimationValue(LatLng value) {
        setLatLng(value);
      }
    };

  private final MapHeroAnimator.AnimationsValueChangeListener<Float> gpsBearingValueListener =
    new MapHeroAnimator.AnimationsValueChangeListener<Float>() {
      @Override
      public void onNewAnimationValue(Float value) {
        boolean trackingNorth = cameraMode == CameraMode.TRACKING_GPS_NORTH
          && mapHeroMap.getCameraPosition().bearing == 0;

        if (!trackingNorth) {
          setBearing(value);
        }
      }
    };

  private final MapHeroAnimator.AnimationsValueChangeListener<Float> compassBearingValueListener =
    new MapHeroAnimator.AnimationsValueChangeListener<Float>() {
      @Override
      public void onNewAnimationValue(Float value) {
        if (cameraMode == CameraMode.TRACKING_COMPASS
          || cameraMode == CameraMode.NONE_COMPASS) {
          setBearing(value);
        }
      }
    };

  private final MapHeroAnimator.AnimationsValueChangeListener<Float> zoomValueListener =
    value -> setZoom(value);

  private final MapHeroAnimator.AnimationsValueChangeListener<double[]> paddingValueListener =
    value -> setPadding(value);

  private final MapHeroAnimator.AnimationsValueChangeListener<Float> tiltValueListener =
    value -> setTilt(value);

  Set<AnimatorListenerHolder> getAnimationListeners() {
    Set<AnimatorListenerHolder> holders = new HashSet<>();
    if (isLocationTracking()) {
      holders.add(new AnimatorListenerHolder(MapHeroAnimator.ANIMATOR_CAMERA_LATLNG, latLngValueListener));
    }

    if (isLocationBearingTracking()) {
      holders.add(new AnimatorListenerHolder(MapHeroAnimator.ANIMATOR_CAMERA_GPS_BEARING, gpsBearingValueListener));
    }

    if (isConsumingCompass()) {
      holders.add(new AnimatorListenerHolder(
        MapHeroAnimator.ANIMATOR_CAMERA_COMPASS_BEARING,
        compassBearingValueListener));
    }

    holders.add(new AnimatorListenerHolder(MapHeroAnimator.ANIMATOR_ZOOM, zoomValueListener));
    holders.add(new AnimatorListenerHolder(MapHeroAnimator.ANIMATOR_TILT, tiltValueListener));
    holders.add(new AnimatorListenerHolder(MapHeroAnimator.ANIMATOR_PADDING, paddingValueListener));
    return holders;
  }

  boolean isTransitioning() {
    return isTransitioning;
  }

  private void adjustGesturesThresholds() {
    if (options.trackingGesturesManagement()) {
      if (isLocationTracking()) {
        moveGestureDetector.setMoveThreshold(options.trackingInitialMoveThreshold());
      } else {
        moveGestureDetector.setMoveThreshold(0f);
        moveGestureDetector.setMoveThresholdRect(null);
      }
    }
  }

  boolean isConsumingCompass() {
    return cameraMode == CameraMode.TRACKING_COMPASS
      || cameraMode == CameraMode.NONE_COMPASS;
  }

  void setEnabled(boolean enabled) {
    isEnabled = enabled;
  }

  private boolean isLocationTracking() {
    return cameraMode == CameraMode.TRACKING
      || cameraMode == CameraMode.TRACKING_COMPASS
      || cameraMode == CameraMode.TRACKING_GPS
      || cameraMode == CameraMode.TRACKING_GPS_NORTH;
  }

  private boolean isBearingTracking() {
    return cameraMode == CameraMode.NONE_COMPASS
      || cameraMode == CameraMode.TRACKING_COMPASS
      || cameraMode == CameraMode.NONE_GPS
      || cameraMode == CameraMode.TRACKING_GPS
      || cameraMode == CameraMode.TRACKING_GPS_NORTH;
  }

  private boolean isLocationBearingTracking() {
    return cameraMode == CameraMode.TRACKING_GPS
      || cameraMode == CameraMode.TRACKING_GPS_NORTH
      || cameraMode == CameraMode.NONE_GPS;
  }

  private void notifyCameraTrackingChangeListener(boolean wasTracking) {
    internalCameraTrackingChangedListener.onCameraTrackingChanged(cameraMode);
    if (wasTracking && !isLocationTracking()) {
      mapHeroMap.getUiSettings().setFocalPoint(null);
      internalCameraTrackingChangedListener.onCameraTrackingDismissed();
    }
  }

  private MapHeroMap.OnCameraMoveListener onCameraMoveListener = new MapHeroMap.OnCameraMoveListener() {

    @Override
    public void onCameraMove() {
      if (isLocationTracking() && lastLocation != null && options.trackingGesturesManagement()) {
        PointF focalPoint = mapHeroMap.getProjection().toScreenLocation(lastLocation);
        mapHeroMap.getUiSettings().setFocalPoint(focalPoint);
      }
    }
  };

  @NonNull
  @VisibleForTesting
  MapHeroMap.OnMoveListener onMoveListener = new MapHeroMap.OnMoveListener() {
    private boolean interrupt;

    @Override
    public void onMoveBegin(@NonNull MoveGestureDetector detector) {
      if (options.trackingGesturesManagement() && isLocationTracking()) {
        if (detector.getPointersCount() > 1) {
          applyMultiFingerThresholdArea(detector);
          applyMultiFingerMoveThreshold(detector);
        } else {
          applySingleFingerMoveThreshold(detector);
        }
      } else {
        setCameraMode(CameraMode.NONE);
      }
    }

    private void applyMultiFingerThresholdArea(@NonNull MoveGestureDetector detector) {
      RectF currentRect = detector.getMoveThresholdRect();
      if (currentRect != null && !currentRect.equals(options.trackingMultiFingerProtectedMoveArea())) {
        detector.setMoveThresholdRect(options.trackingMultiFingerProtectedMoveArea());
        interrupt = true;
      } else if (currentRect == null && options.trackingMultiFingerProtectedMoveArea() != null) {
        detector.setMoveThresholdRect(options.trackingMultiFingerProtectedMoveArea());
        interrupt = true;
      }
    }

    private void applyMultiFingerMoveThreshold(@NonNull MoveGestureDetector detector) {
      if (detector.getMoveThreshold() != options.trackingMultiFingerMoveThreshold()) {
        detector.setMoveThreshold(options.trackingMultiFingerMoveThreshold());
        interrupt = true;
      }
    }

    private void applySingleFingerMoveThreshold(@NonNull MoveGestureDetector detector) {
      if (detector.getMoveThreshold() != options.trackingInitialMoveThreshold()) {
        detector.setMoveThreshold(options.trackingInitialMoveThreshold());
        interrupt = true;
      }
    }

    @Override
    public void onMove(@NonNull MoveGestureDetector detector) {
      if (interrupt) {
        detector.interrupt();
        return;
      }

      if (isLocationTracking() || isBearingTracking()) {
        setCameraMode(CameraMode.NONE);
        detector.interrupt();
      }
    }

    @Override
    public void onMoveEnd(@NonNull MoveGestureDetector detector) {
      if (options.trackingGesturesManagement() && !interrupt && isLocationTracking()) {
        detector.setMoveThreshold(options.trackingInitialMoveThreshold());
        detector.setMoveThresholdRect(null);
      }
      interrupt = false;
    }
  };

  @NonNull
  private MapHeroMap.OnRotateListener onRotateListener = new MapHeroMap.OnRotateListener() {
    @Override
    public void onRotateBegin(@NonNull RotateGestureDetector detector) {
      if (isBearingTracking()) {
        setCameraMode(CameraMode.NONE);
      }
    }

    @Override
    public void onRotate(@NonNull RotateGestureDetector detector) {
      // no implementation
    }

    @Override
    public void onRotateEnd(@NonNull RotateGestureDetector detector) {
      // no implementation
    }
  };

  @NonNull
  private MapHeroMap.OnFlingListener onFlingListener = new MapHeroMap.OnFlingListener() {
    @Override
    public void onFling() {
      setCameraMode(CameraMode.NONE);
    }
  };

  private class LocationGesturesManager extends AndroidGesturesManager {

    LocationGesturesManager(Context context) {
      super(context);
    }

    @Override
    public boolean onTouchEvent(@Nullable MotionEvent motionEvent) {
      if (motionEvent != null) {
        int action = motionEvent.getActionMasked();
        if (action == MotionEvent.ACTION_UP) {
          adjustGesturesThresholds();
        }
      }
      return super.onTouchEvent(motionEvent);
    }
  }
}