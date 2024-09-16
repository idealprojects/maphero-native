import MapHero
import SwiftUI
import UIKit

// #-example-code(SimpleMap)
struct SimpleMap: UIViewRepresentable {
    func makeUIView(context _: Context) -> MHMapView {
        let mapView = MHMapView()
        return mapView
    }

    func updateUIView(_: MHMapView, context _: Context) {}
}

// #-end-example-code
