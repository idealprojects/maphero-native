import MapHero
import XCTest

class MHMapViewDelegateIntegrationTests: XCTestCase {
    func testCoverage() {
        MHSDKTestHelpers.checkTestsContainAllMethods(testClass: MHMapViewDelegateIntegrationTests.self, in: MHMapViewDelegate.self)
    }
}

extension MHMapViewDelegateIntegrationTests: MHMapViewDelegate {
    func mapViewRegionIsChanging(_: MHMapView) {}

    func mapViewRegionIsChanging(_: MHMapView, reason _: MHCameraChangeReason) {}

    func mapView(_: MHMapView, regionIsChangingWith _: MHCameraChangeReason) {}

    func mapView(_: MHMapView, didChange _: MHUserTrackingMode, animated _: Bool) {}

    func mapViewDidFinishLoadingMap(_: MHMapView) {}

    func mapViewDidStopLocatingUser(_: MHMapView) {}

    func mapViewWillStartLoadingMap(_: MHMapView) {}

    func mapViewWillStartLocatingUser(_: MHMapView) {}

    func mapViewWillStartRenderingMap(_: MHMapView) {}

    func mapViewWillStartRenderingFrame(_: MHMapView) {}

    func mapView(_: MHMapView, didFinishLoading _: MHStyle) {}

    func mapView(_: MHMapView, didSelect _: MHAnnotation) {}

    func mapView(_: MHMapView, didDeselect _: MHAnnotation) {}

    func mapView(_: MHMapView, didSingleTapAt _: CLLocationCoordinate2D) {}

    func mapView(_: MHMapView, regionDidChangeAnimated _: Bool) {}

    func mapView(_: MHMapView, regionDidChangeWith _: MHCameraChangeReason, animated _: Bool) {}

    func mapView(_: MHMapView, regionWillChangeAnimated _: Bool) {}

    func mapView(_: MHMapView, regionWillChangeWith _: MHCameraChangeReason, animated _: Bool) {}

    func mapViewDidFailLoadingMap(_: MHMapView, withError _: Error) {}

    func mapView(_: MHMapView, didUpdate _: MHUserLocation?) {}

    func mapViewDidFinishRenderingMap(_: MHMapView, fullyRendered _: Bool) {}

    func mapViewDidBecomeIdle(_: MHMapView) {}

    func mapView(_: MHMapView, didFailToLocateUserWithError _: Error) {}

    func mapView(_: MHMapView, tapOnCalloutFor _: MHAnnotation) {}

    func mapViewDidFinishRenderingFrame(_: MHMapView, fullyRendered _: Bool) {}

    func mapViewDidFinishRenderingFrame(_: MHMapView, fullyRendered _: Bool, frameEncodingTime _: Double, frameRenderingTime _: Double) {}

    func mapView(_: MHMapView, shapeAnnotationIsEnabled _: MHShape) -> Bool { false }

    func mapView(_: MHMapView, didAdd _: [MHAnnotationView]) {}

    func mapView(_: MHMapView, didSelect _: MHAnnotationView) {}

    func mapView(_: MHMapView, didDeselect _: MHAnnotationView) {}

    func mapView(_: MHMapView, alphaForShapeAnnotation _: MHShape) -> CGFloat { 0 }

    func mapView(_: MHMapView, viewFor _: MHAnnotation) -> MHAnnotationView? { nil }

    func mapView(_: MHMapView, imageFor _: MHAnnotation) -> MHAnnotationImage? { nil }

    func mapView(_: MHMapView, annotationCanShowCallout _: MHAnnotation) -> Bool { false }

    func mapView(_: MHMapView, calloutViewFor _: MHAnnotation) -> MHCalloutView? { nil }

    func mapView(_: MHMapView, strokeColorForShapeAnnotation _: MHShape) -> UIColor { .black }

    func mapView(_: MHMapView, fillColorForPolygonAnnotation _: MHPolygon) -> UIColor { .black }

    func mapView(_: MHMapView, leftCalloutAccessoryViewFor _: MHAnnotation) -> UIView? { nil }

    func mapView(_: MHMapView, lineWidthForPolylineAnnotation _: MHPolyline) -> CGFloat { 0 }

    func mapView(_: MHMapView, rightCalloutAccessoryViewFor _: MHAnnotation) -> UIView? { nil }

    func mapView(_: MHMapView, annotation _: MHAnnotation, calloutAccessoryControlTapped _: UIControl) {}

    func mapView(_: MHMapView, shouldChangeFrom _: MHMapCamera, to _: MHMapCamera) -> Bool { false }

    func mapView(_: MHMapView, shouldChangeFrom _: MHMapCamera, to _: MHMapCamera, reason _: MHCameraChangeReason) -> Bool { false }

    func mapViewUserLocationAnchorPoint(_: MHMapView) -> CGPoint { CGPoint(x: 100, y: 100) }

    func mapView(_: MHMapView, didFailToLoadImage _: String) -> UIImage? { nil }

    func mapView(_: MHMapView, shouldRemoveStyleImage _: String) -> Bool { false }

    func mapView(_: MHMapView, didChangeLocationManagerAuthorization _: MHLocationManager) {}

    func mapView(styleForDefaultUserLocationAnnotationView _: MHMapView) -> MHUserLocationAnnotationViewStyle { MHUserLocationAnnotationViewStyle() }
}
