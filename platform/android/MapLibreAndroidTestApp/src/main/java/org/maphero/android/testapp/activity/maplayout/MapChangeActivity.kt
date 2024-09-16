package org.maphero.android.testapp.activity.maplayout

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import org.maphero.android.camera.CameraUpdateFactory
import org.maphero.android.geometry.LatLng
import org.maphero.android.maps.*
import org.maphero.android.maps.MapView.OnCameraDidChangeListener
import org.maphero.android.maps.MapView.OnCameraIsChangingListener
import org.maphero.android.maps.MapView.OnCameraWillChangeListener
import org.maphero.android.maps.MapView.OnDidBecomeIdleListener
import org.maphero.android.maps.MapView.OnDidFailLoadingMapListener
import org.maphero.android.maps.MapView.OnDidFinishLoadingMapListener
import org.maphero.android.maps.MapView.OnDidFinishLoadingStyleListener
import org.maphero.android.maps.MapView.OnDidFinishRenderingFrameListener
import org.maphero.android.maps.MapView.OnDidFinishRenderingMapListener
import org.maphero.android.maps.MapView.OnSourceChangedListener
import org.maphero.android.maps.MapView.OnWillStartLoadingMapListener
import org.maphero.android.maps.MapView.OnWillStartRenderingFrameListener
import org.maphero.android.maps.MapView.OnWillStartRenderingMapListener
import org.maplibre.android.testapp.R
import org.maphero.android.testapp.styles.TestStyles
import timber.log.Timber

/**
 * Test activity showcasing how to listen to map change events.
 */
class MapChangeActivity : AppCompatActivity() {
    private lateinit var mapView: MapView
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_map_simple)
        mapView = findViewById(R.id.mapView)
        mapView.addOnCameraIsChangingListener(OnCameraIsChangingListener { Timber.v("OnCameraIsChanging") })
        mapView.addOnCameraDidChangeListener(
            OnCameraDidChangeListener { animated: Boolean ->
                Timber.v(
                    "OnCamaraDidChange: animated: %s",
                    animated
                )
            }
        )
        mapView.addOnCameraWillChangeListener(
            OnCameraWillChangeListener { animated: Boolean ->
                Timber.v(
                    "OnCameraWilChange: animated: %s",
                    animated
                )
            }
        )
        mapView.addOnDidFailLoadingMapListener(
            OnDidFailLoadingMapListener { errorMessage: String? ->
                Timber.v(
                    "OnDidFailLoadingMap: %s",
                    errorMessage
                )
            }
        )
        mapView.addOnDidFinishLoadingMapListener(OnDidFinishLoadingMapListener { Timber.v("OnDidFinishLoadingMap") })
        mapView.addOnDidFinishLoadingStyleListener(OnDidFinishLoadingStyleListener { Timber.v("OnDidFinishLoadingStyle") })
        mapView.addOnDidFinishRenderingFrameListener(
            OnDidFinishRenderingFrameListener { fully: Boolean, frameEncodingTime: Double, frameRenderingTime: Double ->
                Timber.v(
                    "OnDidFinishRenderingFrame: fully: %s",
                    fully
                )
            }
        )
        mapView.addOnDidFinishRenderingMapListener(
            OnDidFinishRenderingMapListener { fully: Boolean ->
                Timber.v(
                    "OnDidFinishRenderingMap: fully: %s",
                    fully
                )
            }
        )
        mapView.addOnDidBecomeIdleListener(OnDidBecomeIdleListener { Timber.v("OnDidBecomeIdle") })
        mapView.addOnSourceChangedListener(
            OnSourceChangedListener { sourceId: String? ->
                Timber.v(
                    "OnSourceChangedListener: source with id: %s",
                    sourceId
                )
            }
        )
        mapView.addOnWillStartLoadingMapListener(OnWillStartLoadingMapListener { Timber.v("OnWillStartLoadingMap") })
        mapView.addOnWillStartRenderingFrameListener(OnWillStartRenderingFrameListener { Timber.v("OnWillStartRenderingFrame") })
        mapView.addOnWillStartRenderingMapListener(OnWillStartRenderingMapListener { Timber.v("OnWillStartRenderingMap") })
        mapView.onCreate(savedInstanceState)
        mapView.getMapAsync(
            OnMapReadyCallback { mapHeroMap: MapHeroMap ->
                mapHeroMap.setStyle(TestStyles.getPredefinedStyleWithFallback("Streets"))
                mapHeroMap.animateCamera(
                    CameraUpdateFactory.newLatLngZoom(
                        LatLng(55.754020, 37.620948),
                        12.0
                    ),
                    9000
                )
            }
        )
    }

    override fun onStart() {
        super.onStart()
        mapView.onStart()
    }

    override fun onResume() {
        super.onResume()
        mapView.onResume()
    }

    override fun onPause() {
        super.onPause()
        mapView.onPause()
    }

    override fun onStop() {
        super.onStop()
        mapView.onStop()
    }

    override fun onLowMemory() {
        super.onLowMemory()
        mapView.onLowMemory()
    }

    override fun onDestroy() {
        super.onDestroy()
        mapView.onDestroy()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        mapView.onSaveInstanceState(outState)
    }
}
