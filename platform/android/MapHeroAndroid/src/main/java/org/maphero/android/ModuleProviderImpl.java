package org.maphero.android;

import androidx.annotation.NonNull;

import org.maphero.android.http.HttpRequest;
import org.maphero.android.module.http.HttpRequestImpl;
import org.maphero.android.module.loader.LibraryLoaderProviderImpl;

public class ModuleProviderImpl implements ModuleProvider {

  @Override
  @NonNull
  public HttpRequest createHttpRequest() {
    return new HttpRequestImpl();
  }

  @NonNull
  @Override
  public LibraryLoaderProvider createLibraryLoaderProvider() {
    return new LibraryLoaderProviderImpl();
  }
}
