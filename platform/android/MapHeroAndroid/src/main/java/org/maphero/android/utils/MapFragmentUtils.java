package org.maphero.android.utils;

import android.content.Context;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import org.maphero.android.constants.MapHeroConstants;
import org.maphero.android.maps.MapFragment;
import org.maphero.android.maps.SupportMapFragment;
import org.maphero.android.maps.MapHeroMapOptions;

/**
 * MapFragment utility class.
 * <p>
 * Used to extract duplicate code between {@link MapFragment} and
 * {@link SupportMapFragment}.
 * </p>
 */
public class MapFragmentUtils {

  /**
   * Convert MapHeroMapOptions to a bundle of fragment arguments.
   *
   * @param options The MapHeroMapOptions to convert
   * @return a bundle of converted fragment arguments
   */
  @NonNull
  public static Bundle createFragmentArgs(MapHeroMapOptions options) {
    Bundle bundle = new Bundle();
    bundle.putParcelable(MapHeroConstants.FRAG_ARG_MAPLIBREMAPOPTIONS, options);
    return bundle;
  }

  /**
   * Convert a bundle of fragment arguments to MapHeroMapOptions.
   *
   * @param context The context of the activity hosting the fragment
   * @param args    The fragment arguments
   * @return converted MapHeroMapOptions
   */
  @Nullable
  public static MapHeroMapOptions resolveArgs(@NonNull Context context, @Nullable Bundle args) {
    MapHeroMapOptions options;
    if (args != null && args.containsKey(MapHeroConstants.FRAG_ARG_MAPLIBREMAPOPTIONS)) {
      options = args.getParcelable(MapHeroConstants.FRAG_ARG_MAPLIBREMAPOPTIONS);
    } else {
      // load default options
      options = MapHeroMapOptions.createFromAttributes(context);
    }
    return options;
  }
}
