#import "MHAnnotationImage.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MHAnnotationImageDelegate <NSObject>

@required
- (void)annotationImageNeedsRedisplay:(MHAnnotationImage *)annotationImage;

@end

@interface MHAnnotationImage (Private)

/// Unique identifier of the sprite image used by the style to represent the receiver’s `image`.
@property (nonatomic, strong, nullable) NSString *styleIconIdentifier;

@property (nonatomic, weak) id<MHAnnotationImageDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
