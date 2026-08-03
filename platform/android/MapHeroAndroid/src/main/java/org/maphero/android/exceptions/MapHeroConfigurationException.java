package org.maphero.android.exceptions;

import org.maphero.android.MapHero;
import org.maphero.android.WellKnownTileServer;

import android.content.Context;

import androidx.annotation.NonNull;

/**
 * A MapboxConfigurationException is thrown by MapHeroMap when the SDK hasn't been properly initialised.
 * <p>
 * This occurs either when {@link MapHero} is not correctly initialised or the provided apiKey
 * through {@link MapHero#getInstance(Context, String, WellKnownTileServer)} isn't valid.
 * </p>
 *
 * @see MapHero#getInstance(Context, String,  WellKnownTileServer)
 */
public class MapHeroConfigurationException extends RuntimeException {

  /**
   * Creates a MapHero configuration exception thrown by MapHeroMap when the SDK hasn't been properly initialised.
   */
  public MapHeroConfigurationException() {
    super("\nUsing MapView requires calling MapHero.getInstance(Context context, String apiKey, "
            + "WellKnownTileServer wellKnownTileServer) before inflating or creating the view.");
  }

  /**
   * Creates a MapHero configuration exception thrown by MapHeroMap when the SDK hasn't been properly initialised.
   */
  public MapHeroConfigurationException(@NonNull String message) {
    super(message);
  }
}
