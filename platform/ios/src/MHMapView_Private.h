#import "MHAnnotationContainerView.h"
#import "MHMapView.h"
#import "MHUserLocationAnnotationView.h"

#include <mbgl/util/size.hpp>

namespace mbgl {
class Map;
class Renderer;
}  // namespace mbgl

class MHMapViewImpl;
@class MHSource;

/// Standard animation duration for UI elements.
FOUNDATION_EXTERN const NSTimeInterval MHAnimationDuration;

/// Minimum size of an annotation’s accessibility element.
FOUNDATION_EXTERN const CGSize MHAnnotationAccessibilityElementMinimumSize;

/// Indicates that a method (that uses `mbgl::Map`) was called after app termination.
FOUNDATION_EXTERN MH_EXPORT MHExceptionName const _Nonnull MHUnderlyingMapUnavailableException;

@interface MHMapView (Private)

/// The map view’s OpenGL rendering context.
@property (nonatomic, readonly, nullable) EAGLContext *context;

/// Currently shown popover representing the selected annotation.
@property (nonatomic, nonnull) UIView<MHCalloutView> *calloutViewForSelectedAnnotation;

/// Map observers
- (void)cameraWillChangeAnimated:(BOOL)animated;
- (void)cameraIsChanging;
- (void)cameraDidChangeAnimated:(BOOL)animated;
- (void)mapViewWillStartLoadingMap;
- (void)mapViewDidFinishLoadingMap;
- (void)mapViewDidFailLoadingMapWithError:(nonnull NSError *)error;
- (void)mapViewWillStartRenderingFrame;
- (void)mapViewDidFinishRenderingFrameFullyRendered:(BOOL)fullyRendered
                                  frameEncodingTime:(double)frameEncodingTime
                                 frameRenderingTime:(double)frameRenderingTime;
- (void)mapViewWillStartRenderingMap;
- (void)mapViewDidFinishRenderingMapFullyRendered:(BOOL)fullyRendered;
- (void)mapViewDidBecomeIdle;
- (void)mapViewDidFinishLoadingStyle;
- (void)sourceDidChange:(nonnull MHSource *)source;
- (void)didFailToLoadImage:(nonnull NSString *)imageName;
- (BOOL)shouldRemoveStyleImage:(nonnull NSString *)imageName;

- (CLLocationDistance)metersPerPointAtLatitude:(CLLocationDegrees)latitude
                                     zoomLevel:(double)zoomLevel;

/** Triggers another render pass even when it is not necessary. */
- (void)setNeedsRerender;

/// Synchronously render a frame of the map.
- (BOOL)renderSync;

- (mbgl::Map &)mbglMap;
- (nonnull mbgl::Renderer *)renderer;

/** Returns whether the map view is currently loading or processing any assets required to render
 * the map */
- (BOOL)isFullyLoaded;

/** Empties the in-memory tile cache. */
- (void)didReceiveMemoryWarning;

/** Returns an instance of MHMapView implementation. Used for integration testing. */
- (nonnull MHMapViewImpl *)viewImpl;

- (void)pauseRendering:(nonnull NSNotification *)notification;
- (void)resumeRendering:(nonnull NSNotification *)notification;
@property (nonatomic, nonnull) MHUserLocationAnnotationView *userLocationAnnotationView;
@property (nonatomic, nonnull) MHAnnotationContainerView *annotationContainerView;
@property (nonatomic, readonly) BOOL enablePresentsWithTransaction;
@property (nonatomic, assign) BOOL needsDisplayRefresh;

- (MHMapCamera *_Nullable)cameraByTiltingToPitch:(CGFloat)pitch;

- (BOOL)_opaque;

@end
