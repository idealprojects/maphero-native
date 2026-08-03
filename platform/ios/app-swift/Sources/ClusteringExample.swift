import MapHero
import SwiftUI
import UIKit

class ClusteringExampleUIKit: UIViewController, MHMapViewDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        let mapView = MHMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self

        mapView.setCenter(CLLocationCoordinate2D(latitude: 41.8864, longitude: -87.7135), zoomLevel: 2, animated: false)
        view.addSubview(mapView)
    }

    func mapView(_: MHMapView, didFinishLoading style: MHStyle) {
        guard let earthquakesJson = Bundle.main.url(forResource: "earthquakes", withExtension: "geojson"),
              let data = try? Data(contentsOf: earthquakesJson),
              let shape = try? MHShape(data: data, encoding: String.Encoding.utf8.rawValue)
        else {
            preconditionFailure("Failed to load local GeoJSON file earthquakes.json")
        }

        let shapeSource = MHShapeSource(
            identifier: "earthquakes",
            shape: shape,
            options: [
                .clustered: true,
                .clusterRadius: 50,
                .clusterMinPoints: 10,
                .maximumZoomLevelForClustering: 14,
            ]
        )

        style.addSource(shapeSource)

        if let image = UIImage(named: "house-icon") {
            style.setImage(image, forName: "home-symbol")
        }

        let unclusteredLayer = MHSymbolStyleLayer(identifier: "unclustered-symbols", source: shapeSource)
        unclusteredLayer.iconImageName = NSExpression(forConstantValue: "home-symbol")
        unclusteredLayer.iconScale = NSExpression(forConstantValue: 0.5)
        unclusteredLayer.predicate = NSPredicate(format: "cluster != YES")
        style.addLayer(unclusteredLayer)

        let clusterLayer = MHCircleStyleLayer(identifier: "cluster-circles", source: shapeSource)
        clusterLayer.circleColor = NSExpression(forConstantValue: UIColor.red)
        clusterLayer.circleRadius = NSExpression(forConstantValue: 20)
        clusterLayer.predicate = NSPredicate(format: "cluster == YES")
        style.addLayer(clusterLayer)

        let clusterCountLayer = MHSymbolStyleLayer(identifier: "cluster-counts", source: shapeSource)
        clusterCountLayer.text = NSExpression(format: "CAST(point_count, 'NSString')")
        clusterCountLayer.textColor = NSExpression(forConstantValue: UIColor.white)
        clusterCountLayer.textFontSize = NSExpression(forConstantValue: 12)
        clusterCountLayer.predicate = NSPredicate(format: "cluster == YES")
        style.addLayer(clusterCountLayer)
    }
}

struct ClusteringExampleUIViewControllerRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = ClusteringExampleUIKit

    func makeUIViewController(context _: Context) -> ClusteringExampleUIKit {
        ClusteringExampleUIKit()
    }

    func updateUIViewController(_: ClusteringExampleUIKit, context _: Context) {}
}
