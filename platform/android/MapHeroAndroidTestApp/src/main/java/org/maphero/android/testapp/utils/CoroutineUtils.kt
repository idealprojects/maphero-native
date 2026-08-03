package org.maphero.android.testapp.utils

import kotlinx.coroutines.suspendCancellableCoroutine
import org.maphero.android.camera.CameraUpdate
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.MapHeroMap.CancelableCallback
import org.maphero.android.maps.MapView
import kotlin.coroutines.resume

suspend fun MapView.setStyleSuspend(styleUrl: String): Unit =
    suspendCancellableCoroutine { continuation ->
        var listener: MapView.OnDidFinishLoadingStyleListener? = null

        var resumed = false
        listener = MapView.OnDidFinishLoadingStyleListener {
            if (!resumed) {
                resumed = true
                listener?.let { removeOnDidFinishLoadingStyleListener(it) }
                continuation.resume(Unit)
            }
        }
        addOnDidFinishLoadingStyleListener(listener)
        getMapAsync { map -> map.setStyle(styleUrl) }

        continuation.invokeOnCancellation {
            removeOnDidFinishLoadingStyleListener(listener)
        }

    }

suspend fun MapHeroMap.animateCameraSuspend(cameraUpdate: CameraUpdate, durationMs: Int): Unit =
    suspendCancellableCoroutine { continuation ->
        animateCamera(cameraUpdate, durationMs, object : CancelableCallback {
            var resumed = false

            override fun onCancel() {
                continuation.cancel()
            }

            override fun onFinish() {
                if (!resumed) {
                    resumed = true
                    continuation.resume(Unit)
                }
            }
        })
    }
