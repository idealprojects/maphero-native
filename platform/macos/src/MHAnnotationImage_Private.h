#import "Mapbox.h"

@interface MHAnnotationImage (Private)

/// Unique identifier of the sprite image used by the style to represent the receiver’s `image`.
@property (nonatomic, strong, nullable) NSString *styleIconIdentifier;

@end
