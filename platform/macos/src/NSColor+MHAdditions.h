#import <Cocoa/Cocoa.h>

#include <mbgl/style/property_value.hpp>
#include <mbgl/util/color.hpp>

@interface NSColor (MHAdditions)

/**
 Converts the color into an mbgl::Color in sRGB space.
 */
- (mbgl::Color)mgl_color;

- (mbgl::Color)mgl_colorForPremultipliedValue;

/**
 Instantiates `NSColor` from an `mbgl::Color`
 */
+ (NSColor *)mgl_colorWithColor:(mbgl::Color)color;

- (mbgl::style::PropertyValue<mbgl::Color>)mgl_colorPropertyValue;

@end

@interface NSExpression (MHColorAdditions)

+ (NSExpression *)mgl_expressionForRGBComponents:(NSArray<NSExpression *> *)components;
+ (NSExpression *)mgl_expressionForRGBAComponents:(NSArray<NSExpression *> *)components;
+ (NSColor *)mgl_colorWithRGBComponents:(NSArray<NSExpression *> *)componentExpressions;

@end
