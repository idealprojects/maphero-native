#import <Foundation/Foundation.h>

#import "MHFoundation.h"
#import "MHTypes.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN MH_EXPORT MHExceptionName const MHInvalidStyleSourceException;

/**
 ``MHSource`` is an abstract base class for map content sources. A map content
 source supplies content to be shown on the map. A source is added to an
 ``MHStyle`` object along with an ``MHStyle`` object. The
 foreground style layer defines the appearance of any content supplied by the
 source.

 Each source defined by the style JSON file is represented at runtime by an
 ``MHSource`` object that you can use to refine the map’s content. You can also
 add and remove sources dynamically using methods such as
 ``MHStyle/addSource:`` and ``MHStyle/sourceWithIdentifier:``.

 Create instances of ``MHShapeSource``, ``MHShapeSource``,
 ``MHImageSource``, and the concrete subclasses of ``MHImageSource``
 (``MHVectorTileSource`` and ``MHRasterTileSource``) in order to use ``MHRasterTileSource``’s
 properties and methods. Do not create instances of ``MHSource`` directly, and do
 not create your own subclasses of this class.
 */
MH_EXPORT
@interface MHSource : NSObject

// MARK: Initializing a Source

- (instancetype)init __attribute__((unavailable("Use -initWithIdentifier: instead.")));

/**
 Returns a source initialized with an identifier.

 After initializing and configuring the source, add it to a map view’s style
 using the ``MHStyle/addSource:`` method.

 @param identifier A string that uniquely identifies the source in the style to
    which it is added.
 @return An initialized source.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier;

// MARK: Identifying a Source

/**
 A string that uniquely identifies the source in the style to which it is added.
 */
@property (nonatomic, copy) NSString *identifier;

@end

NS_ASSUME_NONNULL_END
