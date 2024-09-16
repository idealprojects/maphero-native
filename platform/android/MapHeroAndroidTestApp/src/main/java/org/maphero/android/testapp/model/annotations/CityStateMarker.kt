package org.maphero.android.testapp.model.annotations

import org.maphero.android.annotations.Marker

class CityStateMarker(
    cityStateOptions: CityStateMarkerOptions?,
    val infoWindowBackgroundColor: String
) : Marker(cityStateOptions)
