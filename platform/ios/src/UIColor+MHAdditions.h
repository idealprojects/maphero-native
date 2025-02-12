#import <UIKit/UIKit.h>

#include <mbgl/style/property_value.hpp>
#include <mbgl/util/color.hpp>

@interface UIColor (MHAdditions)

- (mbgl::Color)mgl_color;

- (mbgl::style::PropertyValue<mbgl::Color>)mgl_colorPropertyValue;

- (mbgl::Color)mgl_colorForPremultipliedValue;

+ (UIColor *)mgl_colorWithColor:(mbgl::Color)color;

@end

@interface NSExpression (MHColorAdditions)

+ (NSExpression *)mgl_expressionForRGBComponents:(NSArray<NSExpression *> *)components;
+ (NSExpression *)mgl_expressionForRGBAComponents:(NSArray<NSExpression *> *)components;
+ (UIColor *)mgl_colorWithRGBComponents:(NSArray<NSExpression *> *)components;

@end
