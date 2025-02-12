package org.maphero.android.location.utils

import android.content.Context
import android.view.View
import androidx.test.espresso.UiController
import androidx.test.espresso.ViewAction
import androidx.test.espresso.matcher.ViewMatchers.isDisplayed
import org.maphero.android.location.LocationComponent
import org.maphero.android.maps.MapHeroMap
import org.maphero.android.maps.Style
import org.hamcrest.Matcher

class LocationComponentAction(
    private val maplibreMap: MapHeroMap,
    private val onPerformLocationComponentAction: OnPerformLocationComponentAction
) : ViewAction {

    override fun getConstraints(): Matcher<View> {
        return isDisplayed()
    }

    override fun getDescription(): String {
        return javaClass.simpleName
    }

    override fun perform(uiController: UiController, view: View) {
        onPerformLocationComponentAction.onLocationComponentAction(
            maplibreMap.locationComponent,
            maplibreMap,
            maplibreMap.style!!,
            uiController,
            view.context
        )
    }

    interface OnPerformLocationComponentAction {
        fun onLocationComponentAction(component: LocationComponent, maplibreMap: MapHeroMap, style: Style, uiController: UiController, context: Context)
    }
}
