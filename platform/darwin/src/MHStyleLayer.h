#import <Foundation/Foundation.h>

#import "MHFoundation.h"
#import "MHTypes.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN MH_EXPORT MHExceptionName const MHInvalidStyleLayerException;

/**
 ``MHStyleLayer`` is an abstract base class for style layers. A style layer
 manages the layout and appearance of content at a specific z-index in a style.
 An ``MHStyle`` object consists of one or more ``MHStyle`` objects.

 Each style layer defined by the style JSON file is represented at runtime by an
 ``MHStyleLayer`` object, which you can use to refine the map’s appearance. You
 can also add and remove style layers dynamically.

 Create instances of ``MHBackgroundStyleLayer`` and the concrete subclasses of
 ``MHForegroundStyleLayer`` in order to use ``MHForegroundStyleLayer``'s properties and methods.
 You do not create instances of ``MHStyleLayer`` directly, and do not
 create your own subclasses of this class.

 Do not add ``MHStyleLayer`` objects to the `style` property of a ``MHStyleLayer`` before
 ``MHMapViewDelegate/mapView:didFinishLoadingStyle:`` is called.
 */
MH_EXPORT
@interface MHStyleLayer : NSObject

// MARK: Initializing a Style Layer

- (instancetype)init
    __attribute__((unavailable("Use -init methods of concrete subclasses instead.")));

// MARK: Identifying a Style Layer

/**
 A string that uniquely identifies the style layer in the style to which it is
 added.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

// MARK: Configuring a Style Layer’s Visibility

/**
 Whether this layer is displayed. A value of `NO` hides the layer.

 #### Related examples
 TODO: Show and hide a layer, learn how to toggle an ``MHStyleLayer``
 object's visibility.
 */
@property (nonatomic, assign, getter=isVisible) BOOL visible;

/**
 The maximum zoom level at which the layer gets parsed and appears. This value is a floating-point
 number.
 */
@property (nonatomic, assign) float maximumZoomLevel;

/**
 The minimum zoom level at which the layer gets parsed and appears. This value is a floating-point
 number.
 */
@property (nonatomic, assign) float minimumZoomLevel;

@end

NS_ASSUME_NONNULL_END
