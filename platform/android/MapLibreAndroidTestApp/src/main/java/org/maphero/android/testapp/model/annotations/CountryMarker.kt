package org.maphero.android.testapp.model.annotations

import org.maphero.android.annotations.BaseMarkerOptions
import org.maphero.android.annotations.Marker

class CountryMarker(
    baseMarkerOptions: BaseMarkerOptions<*, *>?,
    val abbrevName: String,
    val flagRes: Int
) : Marker(baseMarkerOptions)
