import MapHero
import SwiftUI

// #-example-code(OfflinePackExample)
class OfflinePackExample: UIViewController, MHMapViewDelegate {
    var mapView: MHMapView!
    var progressView: UIProgressView!
    let jsonDecoder = JSONDecoder()

    struct UserData: Codable {
        var name: String
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView = MHMapView(frame: view.bounds, styleURL: AMERICANA_STYLE)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.tintColor = .gray
        mapView.delegate = self
        view.addSubview(mapView)

        mapView.setCenter(CLLocationCoordinate2D(latitude: 22.27933, longitude: 114.16281),
                          zoomLevel: 13, animated: false)

        // Setup offline pack notification handlers.
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackProgressDidChange), name: NSNotification.Name.MHOfflinePackProgressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveError), name: NSNotification.Name.MHOfflinePackError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveMaximumAllowedMapboxTiles), name: NSNotification.Name.MHOfflinePackMaximumMapboxTilesReached, object: nil)
    }

    func mapViewDidFinishLoadingMap(_: MHMapView) {
        // Start downloading tiles and resources for z13-14.
        startOfflinePackDownload()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // When leaving this view controller, suspend offline downloads.
        guard let packs = MHOfflineStorage.shared.packs else { return }
        for pack in packs {
            if let userInfo = try? jsonDecoder.decode(UserData.self, from: pack.context) {
                print("Suspending download of offline pack: '\(userInfo.name)'")
            }

            pack.suspend()
        }
    }

    func startOfflinePackDownload() {
        // Create a region that includes the current viewport and any tiles needed to view it when zoomed further in.
        // Because tile count grows exponentially with the maximum zoom level, you should be conservative with your `toZoomLevel` setting.
        let region = MHTilePyramidOfflineRegion(styleURL: mapView.styleURL, bounds: mapView.visibleCoordinateBounds, fromZoomLevel: mapView.zoomLevel, toZoomLevel: 14)

        // Store some data for identification purposes alongside the downloaded resources.
        let jsonEncoder = JSONEncoder()

        let userInfo = UserData(name: "My Offline Pack")
        let encodedUserInfo = try! jsonEncoder.encode(userInfo)
        print(encodedUserInfo)

        // Create and register an offline pack with the shared offline storage object.

        MHOfflineStorage.shared.addPack(for: region, withContext: encodedUserInfo) { pack, error in
            guard error == nil else {
                // The pack couldn’t be created for some reason.
                print("Error: \(error?.localizedDescription ?? "unknown error")")
                return
            }

            // Start downloading.
            pack!.resume()
        }
    }

    // MARK: - MHOfflinePack notification handlers

    @objc func offlinePackProgressDidChange(notification: NSNotification) {
        // Get the offline pack this notification is regarding,
        // and the associated user info for the pack; in this case, `name = My Offline Pack`
        if let pack = notification.object as? MHOfflinePack,
           let userInfo = try? jsonDecoder.decode(UserData.self, from: pack.context)
        {
            let progress = pack.progress
            // or notification.userInfo![MHOfflinePackProgressUserInfoKey]!.MHOfflinePackProgressValue
            let completedResources = progress.countOfResourcesCompleted
            let expectedResources = progress.countOfResourcesExpected

            // Calculate current progress percentage.
            let progressPercentage = Float(completedResources) / Float(expectedResources)

            // Setup the progress bar.
            if progressView == nil {
                progressView = UIProgressView(progressViewStyle: .default)
                let frame = view.bounds.size
                progressView.frame = CGRect(x: frame.width / 4, y: frame.height * 0.75, width: frame.width / 2, height: 10)
                view.addSubview(progressView)
            }

            progressView.progress = progressPercentage

            // If this pack has finished, print its size and resource count.
            if completedResources == expectedResources {
                let byteCount = ByteCountFormatter.string(fromByteCount: Int64(pack.progress.countOfBytesCompleted), countStyle: ByteCountFormatter.CountStyle.memory)
                print("Offline pack “\(userInfo.name)” completed: \(byteCount), \(completedResources) resources")
            } else {
                // Otherwise, print download/verification progress.
                print("Offline pack “\(userInfo.name)” has \(completedResources) of \(expectedResources) resources — \(String(format: "%.2f", progressPercentage * 100))%.")
            }
        }
    }

    @objc func offlinePackDidReceiveError(notification: NSNotification) {
        if let pack = notification.object as? MHOfflinePack,
           let userInfo = try? jsonDecoder.decode(UserData.self, from: pack.context),
           let error = notification.userInfo?[MHOfflinePackUserInfoKey.error] as? NSError
        {
            print("Offline pack “\(userInfo.name)” received error: \(error.localizedFailureReason ?? "unknown error")")
        }
    }

    @objc func offlinePackDidReceiveMaximumAllowedMapboxTiles(notification: NSNotification) {
        if let pack = notification.object as? MHOfflinePack,
           let userInfo = try? jsonDecoder.decode(UserData.self, from: pack.context),
           let maximumCount = (notification.userInfo?[MHOfflinePackUserInfoKey.maximumCount] as AnyObject).uint64Value
        {
            print("Offline pack “\(userInfo.name)” reached limit of \(maximumCount) tiles.")
        }
    }
}

// #-end-example-code

struct OfflinePackExampleUIViewControllerRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = OfflinePackExample

    func makeUIViewController(context _: Context) -> OfflinePackExample {
        OfflinePackExample()
    }

    func updateUIViewController(_: OfflinePackExample, context _: Context) {}
}
