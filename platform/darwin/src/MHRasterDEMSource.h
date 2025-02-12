#import "MHFoundation.h"

#import "MHRasterTileSource.h"

/**
 An `NSNumber` object containing an unsigned integer that specifies the encoding
 formula for raster-dem tilesets. The integer corresponds to one of
 the constants described in ``MHDEMEncoding``.

 The default value for this option is ``MHDEMEncoding/MHDEMEncodingMapbox``.

 This option cannot be represented in a TileJSON or style JSON file. It is used
 with the ``MHRasterDEMSource`` class and is ignored when creating an
 ``MHRasterTileSource`` or ``MHRasterTileSource`` object.
 */
FOUNDATION_EXTERN MH_EXPORT const MHTileSourceOption MHTileSourceOptionDEMEncoding;

/**
 ``MHRasterDEMSource`` is a map content source that supplies rasterized
 <a href="https://en.wikipedia.org/wiki/Digital_elevation_model">digital elevation model</a>
 (DEM) tiles to be shown on the map. The location of and metadata about the
 tiles are defined either by an option dictionary or by an external file that
 conforms to the
 <a href="https://github.com/mapbox/tilejson-spec/">TileJSON specification</a>.
 A raster DEM source is added to an ``MHStyle`` object along with one or more
 ``MHHillshadeStyleLayer`` objects. Use a hillshade style layer to control the
 appearance of content supplied by the raster DEM source.

 Each
 <a href="https://maplibre.org/maplibre-style-spec/#sources-raster-dem"><code>raster-dem</code></a>
 source defined by the style JSON file is represented at runtime by an
 ``MHRasterDEMSource`` object that you can use to initialize new style layers.
 You can also add and remove sources dynamically using methods such as
 ``MHStyle/addSource:`` and ``MHStyle/sourceWithIdentifier:``.

 Currently, raster DEM sources only support the format used by
 <a
 href="https://docs.mapbox.com/help/troubleshooting/access-elevation-data/#mapbox-terrain-rgb">Mapbox
 Terrain-RGB</a>.

 ### Example

 ```swift
 let terrainRGBURL = URL(string: "maptiler://sources/terrain-rgb")!
 let source = MHRasterDEMSource(identifier: "hills", configurationURL: terrainRGBURL)
 mapView.style?.addSource(source)
 ```
 */
MH_EXPORT
@interface MHRasterDEMSource : MHRasterTileSource

@end
