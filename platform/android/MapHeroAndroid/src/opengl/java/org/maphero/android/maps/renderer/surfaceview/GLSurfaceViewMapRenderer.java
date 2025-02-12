package org.maphero.android.maps.renderer.surfaceview;

import android.content.Context;
import androidx.annotation.NonNull;

import org.maphero.android.maps.renderer.egl.EGLConfigChooser;
import org.maphero.android.maps.renderer.egl.EGLContextFactory;
import org.maphero.android.maps.renderer.egl.EGLWindowSurfaceFactory;

import static android.opengl.GLSurfaceView.RENDERMODE_WHEN_DIRTY;

public class GLSurfaceViewMapRenderer extends SurfaceViewMapRenderer {

  public GLSurfaceViewMapRenderer(Context context,
                                @NonNull MapHeroGLSurfaceView surfaceView,
                                String localIdeographFontFamily) {
    super(context, surfaceView, localIdeographFontFamily);

    surfaceView.setEGLContextFactory(new EGLContextFactory());
    surfaceView.setEGLWindowSurfaceFactory(new EGLWindowSurfaceFactory());
    surfaceView.setEGLConfigChooser(new EGLConfigChooser());
    surfaceView.setRenderer(this);
    surfaceView.setRenderMode(RENDERMODE_WHEN_DIRTY);
    surfaceView.setPreserveEGLContextOnPause(true);
  }
}