#import <Mapbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface DroppedPinAnnotation : MHPointAnnotation

@property (nonatomic, copy, nullable) NSString *note;
@property (nonatomic, readonly) NSTimeInterval elapsedShownTime;

- (void)resume;
- (void)pause;

@end

NS_ASSUME_NONNULL_END
