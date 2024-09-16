#import <UIKit/UIKit.h>

#import "MHFoundation.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MHFeature;

/// Unique identifier representing a single annotation in mbgl.
typedef uint64_t MHAnnotationTag;

/** An accessibility element representing something that appears on the map. */
MH_EXPORT
@interface MHMapAccessibilityElement : UIAccessibilityElement

@end

/** An accessibility element representing a map annotation. */
@interface MHAnnotationAccessibilityElement : MHMapAccessibilityElement

/** The tag of the annotation represented by this element. */
@property (nonatomic) MHAnnotationTag tag;

- (instancetype)initWithAccessibilityContainer:(id)container
                                           tag:(MHAnnotationTag)identifier
    NS_DESIGNATED_INITIALIZER;

@end

/** An accessibility element representing a map feature. */
MH_EXPORT
@interface MHFeatureAccessibilityElement : MHMapAccessibilityElement

/** The feature represented by this element. */
@property (nonatomic, strong) id<MHFeature> feature;

- (instancetype)initWithAccessibilityContainer:(id)container
                                       feature:(id<MHFeature>)feature NS_DESIGNATED_INITIALIZER;

@end

/** An accessibility element representing a place feature. */
MH_EXPORT
@interface MHPlaceFeatureAccessibilityElement : MHFeatureAccessibilityElement
@end

/** An accessibility element representing a road feature. */
MH_EXPORT
@interface MHRoadFeatureAccessibilityElement : MHFeatureAccessibilityElement
@end

/** An accessibility element representing the MHMapView at large. */
MH_EXPORT
@interface MHMapViewProxyAccessibilityElement : UIAccessibilityElement
@end

NS_ASSUME_NONNULL_END
