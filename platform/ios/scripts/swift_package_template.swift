// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "MapHero Native",
    products: [
        .library(
            name: "Mapbox",
            targets: ["Mapbox"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
            name: "Mapbox",
            url: "MAPHERO_PACKAGE_URL",
            checksum: "MAPHERO_PACKAGE_CHECKSUM"
        ),
    ]
)
