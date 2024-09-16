package org.maphero.android.testapp.utils

import android.app.Activity
import android.content.Intent
import org.maphero.android.testapp.activity.FeatureOverviewActivity

object NavUtils {
    fun navigateHome(context: Activity) {
        context.startActivity(Intent(context, FeatureOverviewActivity::class.java))
        context.finish()
    }
}
