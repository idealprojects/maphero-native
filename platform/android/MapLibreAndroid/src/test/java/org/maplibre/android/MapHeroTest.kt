package org.maplibre.android

import android.content.Context
import android.content.res.Resources
import android.content.res.TypedArray
import android.util.AttributeSet
import android.util.DisplayMetrics
import org.junit.After
import org.junit.Assert
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.ExpectedException
import org.maplibre.android.MapHeroInjector.clear
import org.maplibre.android.MapHeroInjector.inject
import org.maplibre.android.exceptions.MapHeroConfigurationException
import org.maplibre.android.maps.MapView
import org.maplibre.android.utils.ConfigUtils.Companion.getMockedOptions
import org.mockito.ArgumentMatchers
import org.mockito.Mockito

class MapHeroTest {
    private var context: Context? = null
    private var appContext: Context? = null

    @Rule
    @JvmField // J2K: https://stackoverflow.com/a/33449455
    var expectedException = ExpectedException.none()
    @Before
    fun before() {
        context = Mockito.mock(Context::class.java)
        appContext = Mockito.mock(Context::class.java)
        // J2K: https://www.baeldung.com/kotlin/smart-cast-to-type-is-impossible#2-using-the-safe-call-operator--and-a-scope-function
        Mockito.`when`(context?.getApplicationContext()).thenReturn(appContext)
    }

    @Test
    fun testGetApiKey() {
        val apiKey = "pk.0000000001"
        inject(context!!, apiKey, getMockedOptions())
        Assert.assertSame(apiKey, MapHero.getApiKey())
    }

    @Test
    fun testApplicationContext() {
        inject(context!!, "pk.0000000001", getMockedOptions())
        Assert.assertNotNull(MapHero.getApplicationContext())
        Assert.assertNotEquals(context, appContext)
        Assert.assertEquals(appContext, appContext)
    }

    @Test
    fun testPlainTokenValid() {
        Assert.assertTrue(MapHero.isApiKeyValid("apiKey"))
    }

    @Test
    fun testEmptyToken() {
        Assert.assertFalse(MapHero.isApiKeyValid(""))
    }

    @Test
    fun testNullToken() {
        Assert.assertFalse(MapHero.isApiKeyValid(null))
    }

    @Test
    fun testNoInstance() {
        val displayMetrics = Mockito.mock(DisplayMetrics::class.java)
        val resources = Mockito.mock(Resources::class.java)
        Mockito.`when`(resources.displayMetrics).thenReturn(displayMetrics)
        Mockito.`when`(context!!.resources).thenReturn(resources)
        val typedArray = Mockito.mock(TypedArray::class.java)
        Mockito.`when`(context!!.obtainStyledAttributes(ArgumentMatchers.nullable(AttributeSet::class.java), ArgumentMatchers.any(IntArray::class.java), ArgumentMatchers.anyInt(), ArgumentMatchers.anyInt()))
                .thenReturn(typedArray)
        expectedException.expect(MapHeroConfigurationException::class.java)
        expectedException.expectMessage("""
    
    Using MapView requires calling MapHero.getInstance(Context context, String apiKey) before inflating or creating the view.
    """.trimIndent())
        MapView(context!!)
    }

    @After
    fun after() {
        clear()
    }
}