import MapHero
import SwiftUI
import UIKit

// #-example-code(LocationPrivacyExample)
enum LocationAccuracyState {
    case unknown
    case reducedAccuracy
    case fullAccuracy
}

@MainActor
class PrivacyExampleViewModel: NSObject, ObservableObject {
    @Published var locationAccuracy: LocationAccuracyState = .unknown
    @Published var showTemporaryLocationAuthorization = false
}

class PrivacyExampleCoordinator: NSObject, MHMapViewDelegate {
    @ObservedObject private var mapViewModel: PrivacyExampleViewModel
    private var pannedToUserLocation = false

    init(mapViewModel: PrivacyExampleViewModel) {
        self.mapViewModel = mapViewModel
        super.init()
    }

    @MainActor func mapView(_: MHMapView, didChangeLocationManagerAuthorization manager: MHLocationManager) {
        guard let accuracySetting = manager.accuracyAuthorization else {
            return
        }

        switch accuracySetting() {
        case .fullAccuracy:
            mapViewModel.locationAccuracy = .fullAccuracy
        case .reducedAccuracy:
            mapViewModel.locationAccuracy = .reducedAccuracy
        @unknown default:
            mapViewModel.locationAccuracy = .unknown
        }
    }

    // when a location is available for the first time, we fly to it
    func mapView(_ mapView: MHMapView, didUpdate _: MHUserLocation?) {
        guard !pannedToUserLocation else { return }
        guard let userLocation = mapView.userLocation else {
            print("User location is currently not available.")
            return
        }
        mapView.fly(to: MHMapCamera(lookingAtCenter: userLocation.coordinate, altitude: 100_000, pitch: 0, heading: 0))
        pannedToUserLocation = true
    }
}

struct PrivacyExampleRepresentable: UIViewRepresentable {
    @ObservedObject var mapViewModel: PrivacyExampleViewModel

    func makeCoordinator() -> PrivacyExampleCoordinator {
        PrivacyExampleCoordinator(mapViewModel: mapViewModel)
    }

    func makeUIView(context: Context) -> MHMapView {
        let mapView = MHMapView()

        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ mapView: MHMapView, context _: Context) {
        if mapViewModel.showTemporaryLocationAuthorization {
            let purposeKey = "MHAccuracyAuthorizationDescription"
            mapView.locationManager.requestTemporaryFullAccuracyAuthorization?(withPurposeKey: purposeKey)
            DispatchQueue.main.async {
                mapViewModel.showTemporaryLocationAuthorization = false
            }
        }
    }
}

struct LocationPrivacyExampleView: View {
    @StateObject private var viewModel = PrivacyExampleViewModel()

    var body: some View {
        VStack {
            PrivacyExampleRepresentable(mapViewModel: viewModel)
                .edgesIgnoringSafeArea(.all)

            if viewModel.locationAccuracy == LocationAccuracyState.reducedAccuracy {
                Button("Request Precise Location") {
                    viewModel.showTemporaryLocationAuthorization.toggle()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
}

// #-end-example-code
