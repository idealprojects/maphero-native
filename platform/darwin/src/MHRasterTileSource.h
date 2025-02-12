#import <CoreGraphics/CoreGraphics.h>

#import "MHFoundation.h"
#import "MHTileSource.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An `NSNumber` object containing a floating-point number that specifies the
 width and height (measured in points) at which the map displays each raster
 image tile when the map’s zoom level is an integer. The raster tile source
 scales its images up or down when the map’s zoom level falls between two
 integers.

 The default value for this option is 512. Version 4 of the
 <a href="https://docs.mapbox.com/api/maps/#raster-tiles">Mapbox Raster Tiles API</a>
 requires a value of 256, as do many third-party tile servers, so consult your
 provider’s documentation for the correct value.

 This option is only applicable to ``MHRasterTileSource`` objects; it is ignored
 when initializing ``MHVectorTileSource`` objects.
 */
FOUNDATION_EXTERN MH_EXPORT const MHTileSourceOption MHTileSourceOptionTileSize;

/**
 ``MHRasterTileSource`` is a map content source that supplies raster image tiles
 to be shown on the map. The location of and metadata about the tiles are
 defined either by an option dictionary or by an external file that conforms to
 the
 <a href="https://github.com/mapbox/tilejson-spec/">TileJSON specification</a>.
 A raster tile source is added to an ``MHStyle`` object along with one or more
 ``MHRasterStyleLayer`` objects. Use a raster style layer to control the
 appearance of content supplied by the raster tile source.

 Each
 <a href="https://maplibre.org/maplibre-style-spec/#sources-raster"><code>raster</code></a>
 source defined by the style JSON file is represented at runtime by an
 ``MHRasterTileSource`` object that you can use to initialize new style layers. You
 can also add and remove sources dynamically using methods such as
 ``MHStyle/addSource:`` and ``MHStyle/sourceWithIdentifier:``.

 ### Example

 ```swift
 let source = MHRasterTileSource(identifier: "clouds", tileURLTemplates:
 ["https://example.com/raster-tiles/{z}/{x}/{y}.png"], options: [ .minimumZoomLevel: 9,
     .maximumZoomLevel: 16,
     .tileSize: 512,
     .attributionInfos: [
         MHAttributionInfo(title: NSAttributedString(string: "© Mapbox"), url: URL(string:
 "https://mapbox.com"))
     ]
 ])
 mapView.style?.addSource(source)
 ```

 #### Related examples
 TODO: Add raster imagery, learn how to add a ``MHRasterStyleLayer``
 to your map using an ``MHRasterTileSource``.
 */
MH_EXPORT
@interface MHRasterTileSource : MHTileSource

// MARK: Initializing a Source

/**
 Returns a raster tile source initialized with an identifier and configuration
 URL.

 After initializing and configuring the source, add it to a map view’s style
 using the ``MHStyle/addSource:`` method.

 The URL may be a full HTTP or HTTPS URL or canonical URL. The URL should
 point to a JSON file that conforms to the
 <a href="https://github.com/mapbox/tilejson-spec/">TileJSON specification</a>.

 If a Mapbox URL is specified, this source uses a tile size of 256. For all
 other tilesets, the default value is 512. (See the
 ``MHTileSourceOptionTileSize`` documentation for more information about tile
 sizes.) If you need to use a tile size other than the default, use the
 `-initWithIdentifier:configurationURL:tileSize:` method.

 @param identifier A string that uniquely identifies the source in the style to
    which it is added.
 @param configurationURL A URL to a TileJSON configuration file describing the
    source’s contents and other metadata.
 @return An initialized raster tile source.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier
                  configurationURL:(NSURL *)configurationURL;

/**
 Returns a raster tile source initialized with an identifier, configuration URL,
 and tile size.

 After initializing and configuring the source, add it to a map view’s style
 using the ``MHStyle/addSource:`` method.

 The URL may be a full HTTP or HTTPS URL or, canonical URL. The URL should
 point to a JSON file that conforms to the
 <a href="https://github.com/mapbox/tilejson-spec/">TileJSON specification</a>.

 @param identifier A string that uniquely identifies the source in the style to
    which it is added.
 @param configurationURL A URL to a TileJSON configuration file describing the
 source’s contents and other metadata.
 @param tileSize The width and height (measured in points) of each tiled image
    in the raster tile source. See the ``MHTileSourceOptionTileSize``
    documentation for details.
 @return An initialized raster tile source.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier
                  configurationURL:(NSURL *)configurationURL
                          tileSize:(CGFloat)tileSize NS_DESIGNATED_INITIALIZER;

/**
 Returns a raster tile source initialized an identifier, tile URL templates, and
 options.

 Tile URL templates are strings that specify the URLs of the raster tile images
 to load. See the “<a href="../tile-url-templates.html">Tile URL Templates</a>”
 guide for information about the format of a tile URL template.

 After initializing and configuring the source, add it to a map view’s style
 using the ``MHStyle/addSource:`` method.

 @param identifier A string that uniquely identifies the source in the style to
    which it is added.
 @param tileURLTemplates An array of tile URL template strings. Only the first
    string is used; any additional strings are ignored.
 @param options A dictionary containing configuration options. See
    ``MHTileSourceOption`` for available keys and values. Pass in `nil` to use
    the default values.
 @return An initialized tile source.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier
                  tileURLTemplates:(NSArray<NSString *> *)tileURLTemplates
                           options:(nullable NSDictionary<MHTileSourceOption, id> *)options
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
