#import <Foundation/Foundation.h>

#import "MHFoundation.h"
#import "MHStyleLayer.h"

NS_ASSUME_NONNULL_BEGIN

@class MHSource;

/**
 ``MHForegroundStyleLayer`` is an abstract superclass for style layers whose
 content is defined by an ``MHSource`` object.

 Create instances of ``MHRasterStyleLayer``, ``MHRasterStyleLayer``, and the
 concrete subclasses of ``MHVectorStyleLayer`` in order to use
 ``MHForegroundStyleLayer``'s methods. Do not create instances of
 ``MHForegroundStyleLayer`` directly, and do not create your own subclasses of
 this class.
 */
MH_EXPORT
@interface MHForegroundStyleLayer : MHStyleLayer

// MARK: Initializing a Style Layer

- (instancetype)init
    __attribute__((unavailable("Use -init methods of concrete subclasses instead.")));

// MARK: Specifying a Style Layer’s Content

/**
 Identifier of the source from which the receiver obtains the data to style.
 */
@property (nonatomic, readonly, nullable) NSString *sourceIdentifier;

@end

NS_ASSUME_NONNULL_END
