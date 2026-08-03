#import <UIKit/UIKit.h>

#import "MHTypes.h"

#include <mbgl/style/image.hpp>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN MH_EXPORT MHExceptionName const MHResourceNotFoundException;

@interface UIImage (MHAdditions)

- (nullable instancetype)initWithMHStyleImage:(const mbgl::style::Image &)styleImage;

- (nullable instancetype)initWithMHPremultipliedImage:(const mbgl::PremultipliedImage &&)mbglImage
                                                 scale:(CGFloat)scale;

- (std::unique_ptr<mbgl::style::Image>)mgl_styleImageWithIdentifier:(NSString *)identifier;

- (mbgl::PremultipliedImage)mgl_premultipliedImage;

+ (UIImage *)mgl_resourceImageNamed:(NSString *)imageName;

- (BOOL)isDataEqualTo:(UIImage *)otherImage;

@end

NS_ASSUME_NONNULL_END
