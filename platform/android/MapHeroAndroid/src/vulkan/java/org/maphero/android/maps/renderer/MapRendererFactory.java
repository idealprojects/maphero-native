package org.maphero.android.maps.renderer;

import android.content.Context;
import android.view.Surface;
import android.view.TextureView;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;

import org.maphero.android.maps.renderer.surfaceview.MapHeroVulkanSurfaceView;
import org.maphero.android.maps.renderer.surfaceview.SurfaceViewMapRenderer;
import org.maphero.android.maps.renderer.surfaceview.VulkanSurfaceViewMapRenderer;
import org.maphero.android.maps.renderer.textureview.TextureViewMapRenderer;
import org.maphero.android.maps.renderer.textureview.VulkanTextureViewRenderThread;

@Keep
public class MapRendererFactory {
  public static TextureViewMapRenderer newTextureViewMapRenderer(@NonNull Context context, TextureView textureView,
                                                                 String localFontFamily, boolean translucentSurface,
                                                                 Runnable initCallback) {

    TextureViewMapRenderer mapRenderer = new TextureViewMapRenderer(context, textureView,
            localFontFamily, translucentSurface) {
      @Override
      protected void onSurfaceCreated(Surface surface) {
        initCallback.run();
        super.onSurfaceCreated(surface);
      }
    };

    mapRenderer.setRenderThread(new VulkanTextureViewRenderThread(textureView, mapRenderer));
    return mapRenderer;
  }

  public static SurfaceViewMapRenderer newSurfaceViewMapRenderer(@NonNull Context context, String localFontFamily,
                                                                 boolean renderSurfaceOnTop, Runnable initCallback) {

    MapHeroVulkanSurfaceView surfaceView = new MapHeroVulkanSurfaceView(context);
    surfaceView.setZOrderMediaOverlay(renderSurfaceOnTop);

    return new VulkanSurfaceViewMapRenderer(context, surfaceView, localFontFamily) {
      @Override
      public void onSurfaceCreated(Surface surface) {
        initCallback.run();
        super.onSurfaceCreated(surface);
      }
    };
  }
}
