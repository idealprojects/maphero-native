#import <Foundation/Foundation.h>

#import "MHFoundation.h"
#import "MHSource.h"
#import "MHTypes.h"

NS_ASSUME_NONNULL_BEGIN

@class MHAttributionInfo;

/**
 Options for ``MHTileSource`` objects.
 */
typedef NSString *MHTileSourceOption NS_STRING_ENUM;

/**
 An `NSNumber` object containing an unsigned integer that specifies the minimum
 zoom level at which to display tiles from the source.

 The value should be between 0 and 22, inclusive, and less than
 ``MHTileSourceOptionMaximumZoomLevel``, if specified. The default value for this
 option is 0.

 This option corresponds to the `minzoom` key in the
 <a href="https://github.com/mapbox/tilejson-spec/tree/master/2.1.0">TileJSON</a>
 specification.
 */
FOUNDATION_EXTERN MH_EXPORT const MHTileSourceOption MHTileSourceOptionMinimumZoomLevel;

/**
 An `NSNumber` object containing an unsigned integer that specifies the maximum
 zoom level at which to display tiles from the source.

 The value should be between 0 and 22, inclusive, and less than
 ``MHTileSourceOptionMinimumZoomLevel``, if specified. The default value for this
 option is 22.

 This option corresponds to the `maxzoom` key in the
 <a href="https://github.com/mapbox/tilejson-spec/tree/master/2.1.0">TileJSON</a>
 specification.
 */
FOUNDATION_EXTERN MH_EXPORT const MHTileSourceOption MHTileSourceOptionMaximumZoomLevel;

/**
 An `NSValue` object containing an ``MHCoordinateBounds`` struct that specifies
 the geographic extent of the source.

 If this option is specified, the SDK avoids requesting any tile that falls
 outside of the coordinate bounds. Otherwise, the SDK requests any tile needed
 to cover the viewport, as it does by default.

 This option corresponds to the `bounds` key in the
 <a href="https://github.com/mapbox/tilejson-spec/tree/master/2.1.0">TileJSON</a>
 specification.
 */
FOUNDATION_EXTERN MH_EXPORT const MHTileSourceOption MHTileSourceOptionCoordinateBounds;

#if TARGET_OS_IPHONE
/**
 An HTML string defining the buttons to be displayed in an action sheet when the
 source is part of a map view’s style and the map view’s attribution button is
 pressed.

 By default, no attribution statements are displayed. If the
 ``MHTileSourceOptionAttributionInfos`` option is specified, this option is
 ignored.

 This option corresponds to the `attribution` key in the
 <a href="https://github.com/mapbox/tilejson-spec/tree/master/2.1.0">TileJSON</a>
 specification.
 */
FOUNDATION_EXTERN MH_EXPORT const MHTileSourceOption MHTileSourceOptionAttributionHTMLString;

/**
 An array of ``MHAttributionInfo`` objects defining the buttons to be displayed
 in an action sheet when the source is part of a map view’s style and the map
 view’s attribution button is pressed.

 By default, no attribution statements are displayed.
 */
FOUNDATION_EXTERN MH_EXPORT const MHTileSourceOption MHTileSourceOptionAttributionInfos;
#else
/**
 An HTML string defining the buttons to be displayed in the map view’s
 attribution view when the source is part of the map view’s style.

 By default, no attribution statements are displayed. If the
 ``MHTileSourceOptionAttributionInfos`` option is specified, this option is
 ignored.

 This option corresponds to the `attribution` key in the
 <a href="https://github.com/mapbox/tilejson-spec/tree/master/2.1.0">TileJSON</a>
 specification.
 */
FOUNDATION_EXTERN MH_EXPORT const MHTileSourceOption MHTileSourceOptionAttributionHTMLString;

/**
 An array of ``MHAttributionInfo`` objects defining the buttons to be displayed
 in the map view’s attribution view when the source is part of the map view’s
 style.

 By default, no attribution statements are displayed.
 */
FOUNDATION_EXTERN MH_EXPORT const MHTileSourceOption MHTileSourceOptionAttributionInfos;
#endif

/**
 An `NSNumber` object containing an unsigned integer that specifies the tile
 coordinate system for the source’s tile URLs. The integer corresponds to one of
 the constants described in ``MHTileCoordinateSystem``.

 The default value for this option is ``MHTileCoordinateSystem/MHTileCoordinateSystemXYZ``.

 This option corresponds to the `scheme` key in the
 <a href="https://github.com/mapbox/tilejson-spec/tree/master/2.1.0">TileJSON</a>
 specification.
 */
FOUNDATION_EXTERN MH_EXPORT const MHTileSourceOption MHTileSourceOptionTileCoordinateSystem;

/**
 Tile coordinate systems that determine how tile coordinates in tile URLs are
 interpreted.
 */
typedef NS_ENUM(NSUInteger, MHTileCoordinateSystem) {
  /**
   The origin is at the top-left (northwest), and `y` values increase
   southwards.

   This tile coordinate system is used by Mapbox and OpenStreetMap tile
   servers.
   */
  MHTileCoordinateSystemXYZ = 0,

  /**
   The origin is at the bottom-left (southwest), and `y` values increase
   northwards.

   This tile coordinate system is used by tile servers that conform to the
   <a href="http://wiki.osgeo.org/wiki/Tile_Map_Service_Specification">Tile Map Service
   Specification</a>.
   */
  MHTileCoordinateSystemTMS
};

/**
 The encoding formula used to generate the raster-dem tileset
*/

typedef NS_ENUM(NSUInteger, MHDEMEncoding) {

  /**
   Raster tiles generated with the [Mapbox encoding
   formula](https://docs.mapbox.com/help/troubleshooting/access-elevation-data/#mapbox-terrain-rgb).
  */
  MHDEMEncodingMapbox = 0,

  /**
   Raster tiles generated with the [Mapzen Terrarium encoding
   formula](https://aws.amazon.com/public-datasets/terrain/).
  */
  MHDEMEncodingTerrarium
};

/**
 ``MHTileSource`` is a map content source that supplies map tiles to be shown on
 the map. The location of and metadata about the tiles are defined either by an
 option dictionary or by an external file that conforms to the
 <a href="https://github.com/mapbox/tilejson-spec/">TileJSON specification</a>.
 A tile source is added to an ``MHStyle`` object along with one or more
 ``MHRasterStyleLayer`` or ``MHRasterStyleLayer`` objects. Use a style layer to
 control the appearance of content supplied by the tile source.

 A tile source is also known as a tile set. To learn about the structure of a
 Mapbox-hosted tile set, view it in
 <a href="https://www.mapbox.com/studio/tilesets/">Mapbox Studio’s Tilesets editor</a>.

 Create instances of ``MHRasterTileSource`` and ``MHRasterTileSource`` in order
 to use ``MHTileSource``'s properties and methods. Do not create instances of
 ``MHTileSource`` directly, and do not create your own subclasses of this class.
 */
MH_EXPORT
@interface MHTileSource : MHSource

// MARK: Accessing a Source’s Content

/**
 The URL to the TileJSON configuration file that specifies the contents of the
 source.

 If the receiver was initialized using
 `-initWithIdentifier:tileURLTemplates:options`, this property is set to `nil`.
 */
@property (nonatomic, copy, nullable, readonly) NSURL *configurationURL;

// MARK: Accessing Attribution Strings

/**
 An array of ``MHAttributionInfo`` objects that define the attribution
 statements to be displayed when the map is shown to the user.

 By default, this array is empty. If the source is initialized with a
 configuration URL, this array is also empty until the configuration JSON file
 is loaded.
 */
@property (nonatomic, copy, readonly) NSArray<MHAttributionInfo *> *attributionInfos;

@end

NS_ASSUME_NONNULL_END
