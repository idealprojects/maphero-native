package org.maphero.android.location.permissions;

import java.util.List;

/**
 * Callback used in PermissionsManager
 */

public interface PermissionsListener {

  void onExplanationNeeded(List<String> permissionsToExplain);

  void onPermissionResult(boolean granted);
}
