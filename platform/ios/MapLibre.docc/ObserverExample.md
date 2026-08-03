# Observe Low-Level Events

Learn about the ``MHMapViewDelegate`` methods for observing map events.

> Warning: These methods are not thread-safe.

You can observe certain low-level events as they happen. Use these methods to collect metrics or investigate issues during map rendering. This feature is intended primarily for power users. We are always interested in improving observability, so if you have a special use case, feel free to [open an issue or pull request](https://github.com/maplibre/maplibre-native) to extend the types of observability methods.

## Frame Events

Observe frame rendering statistics with ``MHMapViewDelegate/mapViewDidFinishRenderingFrame:fullyRendered:renderingStats:``.

<!-- include-example(ObserverExampleRenderingStats) -->

```swift
func mapViewDidFinishRenderingFrame(_: MHMapView, fullyRendered: Bool, renderingStats: MHRenderingStats) {

    }
```

See also: ``MHMapViewDelegate/mapViewDidFinishRenderingFrame:fullyRendered:`` and ``MHMapViewDelegate/mapViewDidFinishRenderingFrame:fullyRendered:frameEncodingTime:frameRenderingTime:``

## Shader Events

Observe shader compilation with ``MHMapViewDelegate/mapView:shaderWillCompile:backend:defines:`` and ``MHMapViewDelegate/mapView:shaderDidCompile:backend:defines:``.

<!-- include-example(ObserverExampleShaders) -->

```swift
func mapView(_: MHMapView, shaderWillCompile id: Int, backend: Int, defines: String) {
        print("A new shader is being compiled - shaderID:\(id), backend type:\(backend), program configuration:\(defines)")
    }

    func mapView(_: MHMapView, shaderDidCompile id: Int, backend: Int, defines: String) {
        print("A shader has been compiled - shaderID:\(id), backend type:\(backend), program configuration:\(defines)")
    }
```

See also: ``MHMapViewDelegate/mapView:shaderDidFailCompile:backend:defines:``.

## Glyph Loading

Observe glyph loading events with ``MHMapViewDelegate/mapView:glyphsWillLoad:range:`` and ``MHMapViewDelegate/mapView:glyphsDidLoad:range:``.

<!-- include-example(ObserverExampleGlyphs) -->

```swift
func mapView(_: MHMapView, glyphsWillLoad fontStack: [String], range: NSRange) {
        print("Glyphs are being requested for the font stack \(fontStack), ranging from \(range.location) to \(range.location + range.length)")
    }

    func mapView(_: MHMapView, glyphsDidLoad fontStack: [String], range: NSRange) {
        print("Glyphs have been loaded for the font stack \(fontStack), ranging from \(range.location) to \(range.location + range.length)")
    }
```

See also: ``MHMapViewDelegate/mapView:glyphsDidError:range:``.

## Tile Events

Monitor tile-related actions using the delegate method ``MHMapViewDelegate/mapView:tileDidTriggerAction:x:y:z:wrap:overscaledZ:sourceID:`` with the ``MHTileOperation`` type.

<!-- include-example(ObserverExampleTiles) -->

```swift
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
```

## Sprite Loading

Observe sprite loading events with ``MHMapViewDelegate/mapView:spriteWillLoad:url:`` and ``MHMapViewDelegate/mapView:spriteDidLoad:url:``.

<!-- include-example(ObserverExampleSprites) -->

```swift
func mapView(_: MHMapView, spriteWillLoad id: String, url: String) {
        print("The sprite \(id) has been requested from \(url)")
    }

    func mapView(_: MHMapView, spriteDidLoad id: String, url: String) {
        print("The sprite \(id) has been loaded from \(url)")
    }
```

See also: ``MHMapViewDelegate/mapView:spriteDidError:url:``.
