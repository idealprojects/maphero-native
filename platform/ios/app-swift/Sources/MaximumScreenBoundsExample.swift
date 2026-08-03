import MapHero
import SwiftUI
import UIKit

// Denver, Colorado
private let center = CLLocationCoordinate2D(latitude: 39.748947, longitude: -104.995882)

// Colorado’s bounds
private let colorado = MHCoordinateBounds(
    sw: CLLocationCoordinate2D(latitude: 36.986207, longitude: -109.049896),
    ne: CLLocationCoordinate2D(latitude: 40.989329, longitude: -102.062592)
)

struct MaximumScreenBoundsExample: UIViewRepresentable {
    func makeUIView(context _: Context) -> MHMapView {
        let mapView = MHMapView(frame: .zero, styleURL: VERSATILES_COLORFUL_STYLE)
        mapView.setCenter(center, zoomLevel: 10, direction: 0, animated: false)
        mapView.maximumScreenBounds = MHCoordinateBounds(sw: colorado.sw, ne: colorado.ne)

        return mapView
    }

    func updateUIView(_: MHMapView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}
