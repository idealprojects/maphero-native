import MapHero
import SwiftUI
import UIKit

class ObserverExampleView: UIViewController, MHMapViewDelegate {
    var mapView: MHMapView!
    var button: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // #-example-code(actionJournalOptions)
        let options = MHMapOptions()
        options.actionJournalOptions.enabled = true
        options.actionJournalOptions.renderingStatsReportInterval = 10
        options.styleURL = AMERICANA_STYLE
        mapView = MHMapView(frame: view.bounds, options: options)
        // #-end-example-code

        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(mapView)

        mapView.delegate = self

        button = UIButton(frame: CGRect(x: view.bounds.width / 2 - 100, y: view.bounds.height - 200, width: 200, height: 30))
        button.setTitle("Print Action Journal", for: .normal)
        button.layer.cornerRadius = 15
        button.backgroundColor = UIColor(red: 0.96, green: 0.65, blue: 0.14, alpha: 1.0)
        button.addTarget(self, action: #selector(printActionJournal), for: .touchUpInside)
        view.addSubview(button)
    }

    // #-example-code(ObserverExampleActionJournal)
    @objc func printActionJournal() {
        print("ActionJournalLog files: \(mapView.getActionJournalLogFiles())")
        print("ActionJournalLog : \(mapView.getActionJournalLog())")
        // print only the newest events on each call
        mapView.clearActionJournalLog()
    }

    // #-end-example-code

    func mapViewDidFinishLoadingMap(_: MHMapView) {
        // #-example-code(enableRenderingStatsView)
        mapView.enableRenderingStatsView(true)
        // #-end-example-code
    }

    // #-example-code(ObserverExampleRenderingStats)
    func mapViewDidFinishRenderingFrame(_: MHMapView, fullyRendered _: Bool, renderingStats _: MHRenderingStats) {}

    // #-end-example-code

    // #-example-code(ObserverExampleShaders)
    func mapView(_: MHMapView, shaderWillCompile id: Int, backend: Int, defines: String) {
        print("A new shader is being compiled - shaderID:\(id), backend type:\(backend), program configuration:\(defines)")
    }

    func mapView(_: MHMapView, shaderDidCompile id: Int, backend: Int, defines: String) {
        print("A shader has been compiled - shaderID:\(id), backend type:\(backend), program configuration:\(defines)")
    }

    // #-end-example-code

    // #-example-code(ObserverExampleGlyphs)
    func mapView(_: MHMapView, glyphsWillLoad fontStack: [String], range: NSRange) {
        print("Glyphs are being requested for the font stack \(fontStack), ranging from \(range.location) to \(range.location + range.length)")
    }

    func mapView(_: MHMapView, glyphsDidLoad fontStack: [String], range: NSRange) {
        print("Glyphs have been loaded for the font stack \(fontStack), ranging from \(range.location) to \(range.location + range.length)")
    }

    // #-end-example-code

    // #-example-code(ObserverExampleTiles)
    func mapView(_: MHMapView, tileDidTriggerAction operation: MHTileOperation,
                 x: Int,
                 y: Int,
                 z: Int,
                 wrap: Int,
                 overscaledZ: Int,
                 sourceID: String)
    {
        let tileStr = String(format: "(x: %ld, y: %ld, z: %ld, wrap: %ld, overscaledZ: %ld, sourceID: %@)",
                             x, y, z, wrap, overscaledZ, sourceID)

        switch operation {
        case MHTileOperation.requestedFromCache:
            print("Requesting tile \(tileStr) from cache")

        case MHTileOperation.requestedFromNetwork:
            print("Requesting tile \(tileStr) from network")

        case MHTileOperation.loadFromCache:
            print("Loading tile \(tileStr), requested from the cache")

        case MHTileOperation.loadFromNetwork:
            print("Loading tile \(tileStr), requested from the network")

        case MHTileOperation.startParse:
            print("Parsing tile \(tileStr)")

        case MHTileOperation.endParse:
            print("Completed parsing tile \(tileStr)")

        case MHTileOperation.error:
            print("An error occured during proccessing for tile \(tileStr)")

        case MHTileOperation.cancelled:
            print("Pending work on tile \(tileStr)")

        case MHTileOperation.nullOp:
            print("An unknown tile operation was emitted for tile \(tileStr)")

        @unknown default:
            assertionFailure()
        }
    }

    // #-end-example-code

    // #-example-code(ObserverExampleSprites)
    func mapView(_: MHMapView, spriteWillLoad id: String, url: String) {
        print("The sprite \(id) has been requested from \(url)")
    }

    func mapView(_: MHMapView, spriteDidLoad id: String, url: String) {
        print("The sprite \(id) has been loaded from \(url)")
    }
    // #-end-example-code
}

struct ObserverExampleViewUIViewControllerRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = ObserverExampleView

    func makeUIViewController(context _: Context) -> ObserverExampleView {
        ObserverExampleView()
    }

    func updateUIViewController(_: ObserverExampleView, context _: Context) {}
}
