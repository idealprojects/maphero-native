package org.maphero.android.maps;

import android.graphics.RectF;

import org.maphero.android.annotations.Annotation;

import java.util.List;

interface ShapeAnnotations {

  List<Annotation> obtainAllIn(RectF rectF);

}
