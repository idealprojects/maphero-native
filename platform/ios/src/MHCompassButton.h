#import <UIKit/UIKit.h>

#import "MHTypes.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A specialized view that displays the current compass heading for its associated map.
 */
MH_EXPORT
@interface MHCompassButton : UIImageView

/**
 The visibility of the compass button.

 You can configure a compass button to be visible all the time or only when the compass heading
 changes.
 */
@property (nonatomic, assign) MHOrnamentVisibility compassVisibility;

@end

NS_ASSUME_NONNULL_END
