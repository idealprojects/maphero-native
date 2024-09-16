package org.maphero.android.exceptions;

import org.maphero.android.MapHero;

import android.content.Context;

import androidx.annotation.NonNull;

/**
 * A MapboxConfigurationException is thrown by MapLibreMap when the SDK hasn't been properly initialised.
 * <p>
 * This occurs either when {@link MapHero} is not correctly initialised or the provided apiKey
 * through {@link MapHero#getInstance(Context, String)} isn't valid.
 * </p>
 *
 * @see MapHero#getInstance(Context, String)
 */
public class MapHeroConfigurationException extends RuntimeException {

  /**
   * Creates a MapLibre configuration exception thrown by MapLibreMap when the SDK hasn't been properly initialised.
   */
  public MapHeroConfigurationException() {
    super("\nUsing MapView requires calling MapHero.getInstance(Context context, String apiKey) before inflating or creating the view.");
  }

  /**
   * Creates a MapLibre configuration exception thrown by MapLibreMap when the SDK hasn't been properly initialised.
   */
  public MapHeroConfigurationException(@NonNull String message) {
    super(message);
  }
}
