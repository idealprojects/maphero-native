package org.maphero.android.testapp.utils

import org.maphero.android.LibraryLoaderProvider
import org.maphero.android.ModuleProvider
import org.maphero.android.http.HttpRequest
import org.maphero.android.module.loader.LibraryLoaderProviderImpl
import org.maphero.android.testapp.utils.ExampleHttpRequestImpl

/*
 * An example implementation of the ModuleProvider. This is useful primarily for providing
 * a custom implementation of HttpRequest used by the core.
 */
class ExampleCustomModuleProviderImpl : ModuleProvider {
    override fun createHttpRequest(): HttpRequest {
        return ExampleHttpRequestImpl()
    }

    override fun createLibraryLoaderProvider(): LibraryLoaderProvider {
        return LibraryLoaderProviderImpl()
    }
}
