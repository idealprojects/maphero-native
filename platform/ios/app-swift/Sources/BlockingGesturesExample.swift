import MapHero
import SwiftUI
import UIKit

// #-example-code(BlockingGesturesExample)
// Denver, Colorado
private let center = CLLocationCoordinate2D(latitude: 39.748947, longitude: -104.995882)

// Colorado’s bounds
private let colorado = MHCoordinateBounds(
    sw: CLLocationCoordinate2D(latitude: 36.986207, longitude: -109.049896),
    ne: CLLocationCoordinate2D(latitude: 40.989329, longitude: -102.062592)
)

struct BlockingGesturesExample: UIViewRepresentable {
    class Coordinator: NSObject, MHMapViewDelegate {
        func mapView(_ mapView: MHMapView, shouldChangeFrom _: MHMapCamera, to newCamera: MHMapCamera) -> Bool {
            // Get the current camera to restore it after.
            let currentCamera = mapView.camera

            // From the new camera obtain the center to test if it’s inside the boundaries.
            let newCameraCenter = newCamera.centerCoordinate

            // Set the map’s visible bounds to newCamera.
            mapView.camera = newCamera
            let newVisibleCoordinates = mapView.visibleCoordinateBounds

            // Revert the camera.
            mapView.camera = currentCamera

            // Test if the newCameraCenter and newVisibleCoordinates are inside self.colorado.
            let inside = MHCoordinateInCoordinateBounds(newCameraCenter, colorado)
            let intersects = MHCoordinateInCoordinateBounds(newVisibleCoordinates.ne, colorado) && MHCoordinateInCoordinateBounds(newVisibleCoordinates.sw, colorado)

            return inside && intersects
        }
    }

    func makeUIView(context: Context) -> MHMapView {
        let mapView = MHMapView(frame: .zero, styleURL: VERSATILES_COLORFUL_STYLE)
        mapView.setCenter(center, zoomLevel: 10, direction: 0, animated: false)
        mapView.delegate = context.coordinator

        return mapView
    }

    func updateUIView(_: MHMapView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

// #-end-example-code
