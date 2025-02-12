package org.maphero.android.testapp.activity.style

import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.appcompat.app.AppCompatActivity
import org.maphero.android.MapHero
import org.maphero.android.geometry.LatLng
import org.maphero.android.geometry.LatLngQuad
import org.maphero.android.maps.MapView
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.OnMapReadyCallback
import org.maphero.android.maps.Style
import org.maphero.android.style.layers.RasterLayer
import org.maphero.android.style.sources.ImageSource
import org.maphero.android.testapp.R
import org.maphero.android.testapp.styles.TestStyles
import org.maphero.android.utils.BitmapUtils

/**
 * Test activity showing how to use a series of images to create an animation
 * with an ImageSource
 *
 *
 * GL-native equivalent of https://maplibre.org/maplibre-gl-js-docs/example/animate-images/
 *
 */
class AnimatedImageSourceActivity : AppCompatActivity(), OnMapReadyCallback {
    private lateinit var mapView: MapView
    private val handler = Handler(Looper.getMainLooper())
    private var runnable: Runnable? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_animated_image_source)
        mapView = findViewById(R.id.mapView)
        mapView.onCreate(savedInstanceState)
        mapView.getMapAsync(this)
    }

    override fun onMapReady(mapHeroMap: MapHeroMap) {
        val quad = LatLngQuad(
            LatLng(46.437, -80.425),
            LatLng(46.437, -71.516),
            LatLng(37.936, -71.516),
            LatLng(37.936, -80.425)
        )
        val imageSource = ImageSource(ID_IMAGE_SOURCE, quad, R.drawable.southeast_radar_0)
        val layer = RasterLayer(ID_IMAGE_LAYER, ID_IMAGE_SOURCE)
        mapHeroMap.setStyle(
            Style.Builder()
                .fromUri(TestStyles.getPredefinedStyleWithFallback("Streets"))
                .withSource(imageSource)
                .withLayer(layer)
        ) { style: Style? ->
            runnable = RefreshImageRunnable(imageSource, handler)
            runnable?.let {
                handler.postDelayed(it, 100)
            }
        }
    }

    override fun onStart() {
        super.onStart()
        mapView.onStart()
    }

    public override fun onResume() {
        super.onResume()
        mapView.onResume()
    }

    public override fun onPause() {
        super.onPause()
        mapView.onPause()
    }

    override fun onStop() {
        super.onStop()
        mapView.onStop()
        runnable?.let {
            handler.removeCallbacks(it)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        mapView.onDestroy()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        mapView.onSaveInstanceState(outState)
    }

    private class RefreshImageRunnable internal constructor(
        private val imageSource: ImageSource,
        private val handler: Handler
    ) : Runnable {
        private val drawables: Array<Bitmap?>
        private var drawableIndex: Int
        fun getBitmap(resourceId: Int): Bitmap? {
            val context = MapHero.getApplicationContext()
            val drawable = BitmapUtils.getDrawableFromRes(context, resourceId)
            if (drawable is BitmapDrawable) {
                return drawable.bitmap
            }
            return null
        }

        override fun run() {
            imageSource.setImage(drawables[drawableIndex++]!!)
            if (drawableIndex > 3) {
                drawableIndex = 0
            }
            handler.postDelayed(this, 1000)
        }

        init {
            drawables = arrayOfNulls(4)
            drawables[0] = getBitmap(R.drawable.southeast_radar_0)
            drawables[1] = getBitmap(R.drawable.southeast_radar_1)
            drawables[2] = getBitmap(R.drawable.southeast_radar_2)
            drawables[3] = getBitmap(R.drawable.southeast_radar_3)
            drawableIndex = 1
        }
    }

    companion object {
        private const val ID_IMAGE_SOURCE = "animated_image_source"
        private const val ID_IMAGE_LAYER = "animated_image_layer"
    }
}
