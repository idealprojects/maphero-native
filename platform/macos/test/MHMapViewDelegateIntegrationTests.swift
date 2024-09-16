import Mapbox
import XCTest

class MHMapViewDelegateIntegrationTests: XCTestCase {
    func testCoverage() {
        MHSDKTestHelpers.checkTestsContainAllMethods(testClass: MHMapViewDelegateIntegrationTests.self, in: MHMapViewDelegate.self)
    }
}

extension MHMapViewDelegateIntegrationTests: MHMapViewDelegate {
    func mapView(_: MHMapView, shouldChangeFrom _: MHMapCamera, to _: MHMapCamera) -> Bool { false }

    func mapView(_: MHMapView, lineWidthForPolylineAnnotation _: MHPolyline) -> CGFloat { 0 }

    func mapView(_: MHMapView, annotationCanShowCallout _: MHAnnotation) -> Bool { false }

    func mapView(_: MHMapView, imageFor _: MHAnnotation) -> MHAnnotationImage? { nil }

    func mapView(_: MHMapView, alphaForShapeAnnotation _: MHShape) -> CGFloat { 0 }

    func mapViewDidFinishRenderingFrame(_: MHMapView, fullyRendered _: Bool) {}

    func mapViewDidFinishRenderingFrame(_: MHMapView, fullyRendered _: Bool, frameTime _: Double) {}

    func mapViewDidFinishRenderingMap(_: MHMapView, fullyRendered _: Bool) {}

    func mapViewDidBecomeIdle(_: MHMapView) {}

    func mapViewDidFailLoadingMap(_: MHMapView, withError _: Error) {}

    func mapView(_: MHMapView, didFailToLoadImage _: String) -> NSImage? { nil }

    func mapView(_: MHMapView, shapeAnnotationIsEnabled _: MHShape) -> Bool { false }

    func mapView(_: MHMapView, didDeselect _: MHAnnotation) {}

    func mapView(_: MHMapView, didSelect _: MHAnnotation) {}

    func mapView(_: MHMapView, didFinishLoading _: MHStyle) {}

    func mapViewWillStartRenderingFrame(_: MHMapView) {}

    func mapViewWillStartRenderingMap(_: MHMapView) {}

    func mapViewWillStartLoadingMap(_: MHMapView) {}

    func mapViewDidFinishLoadingMap(_: MHMapView) {}

    func mapViewCameraIsChanging(_: MHMapView) {}

    func mapView(_: MHMapView, cameraDidChangeAnimated _: Bool) {}

    func mapView(_: MHMapView, cameraWillChangeAnimated _: Bool) {}

    func mapView(_: MHMapView, strokeColorForShapeAnnotation _: MHShape) -> NSColor { .black }

    func mapView(_: MHMapView, fillColorForPolygonAnnotation _: MHPolygon) -> NSColor { .black }

    func mapView(_: MHMapView, calloutViewControllerFor _: MHAnnotation) -> NSViewController? { nil }

    func mapView(_: MHMapView, shouldRemoveStyleImage _: String) -> Bool { false }
}
