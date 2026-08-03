#import <Foundation/Foundation.h>

#import "MHFoundation.h"
#import "MHStyleLayer.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A style layer that renders glTF (.glb) building models inside the map's own
 render pass — true map geometry, depth-tested against 3D layers and controlled
 by the standard minimum/maximum zoom and visibility mechanisms.

 Models are supplied as a GeoJSON `FeatureCollection` of `Point` features:
 the geometry is the anchor (the model's baked footprint center lands on it,
 base grounded at terrain level), and the recognized properties are:

 - `path` (string, required): absolute filesystem path or `file://` URI of the .glb
 - `heading` (number, optional): rotation around the up axis, in degrees
 - `size` (number, optional): largest horizontal extent the model is auto-fitted
   to, in meters (default 180)

 ```swift
 let layer = MHModel3DStyleLayer(identifier: "buildings-3d")
 layer.setData(featureCollectionJSON)
 layer.maximumZoomLevel = 16.5
 style.addLayer(layer)
 ```
 */
MH_EXPORT
@interface MHModel3DStyleLayer : MHStyleLayer

- (instancetype)initWithIdentifier:(NSString *)identifier;

/**
 Replaces the rendered models with the Point features of the given GeoJSON
 `FeatureCollection` (a single `Feature` is also accepted).
 */
- (void)setData:(NSString *)featureCollectionJSON;

@end

NS_ASSUME_NONNULL_END
