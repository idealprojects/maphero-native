package org.maphero.android.maps.renderer.surfaceview;

import android.content.Context;
import androidx.annotation.NonNull;

public class VulkanSurfaceViewMapRenderer extends SurfaceViewMapRenderer {

  public VulkanSurfaceViewMapRenderer(Context context,
                                @NonNull MapHeroVulkanSurfaceView surfaceView,
                                String localIdeographFontFamily) {
    super(context, surfaceView, localIdeographFontFamily);

    this.surfaceView.setRenderer(this);
  }

}