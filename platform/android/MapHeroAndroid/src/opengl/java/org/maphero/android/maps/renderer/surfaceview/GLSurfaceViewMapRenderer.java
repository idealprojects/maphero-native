package org.maphero.android.maps.renderer.surfaceview;

import android.content.Context;
import androidx.annotation.NonNull;

import org.maphero.android.maps.renderer.egl.EGLConfigChooser;
import org.maphero.android.maps.renderer.egl.EGLContextFactory;
import org.maphero.android.maps.renderer.egl.EGLWindowSurfaceFactory;
import org.maphero.android.maps.renderer.MapRenderer;

public class GLSurfaceViewMapRenderer extends SurfaceViewMapRenderer {

  public GLSurfaceViewMapRenderer(Context context,
                                @NonNull MapHeroGLSurfaceView surfaceView,
                                String localIdeographFontFamily) {
    super(context, surfaceView, localIdeographFontFamily);

    surfaceView.setEGLContextFactory(new EGLContextFactory());
    surfaceView.setEGLWindowSurfaceFactory(new EGLWindowSurfaceFactory());
    surfaceView.setEGLConfigChooser(new EGLConfigChooser());
    surfaceView.setRenderer(this);
    surfaceView.setRenderingRefreshMode(MapRenderer.RenderingRefreshMode.WHEN_DIRTY);
    surfaceView.setPreserveEGLContextOnPause(true);
  }
}
