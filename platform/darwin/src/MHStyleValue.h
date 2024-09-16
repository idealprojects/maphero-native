#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

#import "MHFoundation.h"
#import "MHTypes.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString *MHStyleFunctionOption NS_STRING_ENUM NS_UNAVAILABLE;

FOUNDATION_EXTERN MH_EXPORT const MHStyleFunctionOption MHStyleFunctionOptionInterpolationBase
    __attribute__((unavailable(
        "Use NSExpression instead, applying the mgl_interpolate:withCurveType:parameters:stops: "
        "function with a curve type of “exponential” and a non-nil parameter.")));

FOUNDATION_EXTERN MH_EXPORT const MHStyleFunctionOption MHStyleFunctionOptionDefaultValue
    __attribute__((unavailable(
        "Use +[NSExpression expressionForConditional:trueExpression:falseExpression:] instead.")));

typedef NS_ENUM(NSUInteger, MHInterpolationMode) {
  MHInterpolationModeExponential __attribute__((unavailable(
      "Use NSExpression instead, applying the mgl_interpolate:withCurveType:parameters:stops: "
      "function with a curve type of “exponential”."))) = 0,
  MHInterpolationModeInterval __attribute__((
      unavailable("Use NSExpression instead, calling the mgl_step:from:stops: function."))),
  MHInterpolationModeCategorical __attribute__((unavailable("Use NSExpression instead."))),
  MHInterpolationModeIdentity
  __attribute__((unavailable("Use +[NSExpression expressionForKeyPath:] instead.")))
} __attribute__((unavailable("Use NSExpression instead.")));

MH_EXPORT __attribute__((unavailable("Use NSExpression instead.")))
@interface MHStyleValue<T> : NSObject
@end

MH_EXPORT __attribute__((unavailable("Use +[NSExpression expressionForConstantValue:] instead.")))
@interface MHConstantStyleValue<T> : MHStyleValue<T>
@end

@compatibility_alias MHStyleConstantValue MHConstantStyleValue;

MH_EXPORT
__attribute__((unavailable("Use NSExpression instead, calling the mgl_step:from:stops: or "
                           "mgl_interpolate:withCurveType:parameters:stops: function.")))
@interface MHStyleFunction<T> : MHStyleValue<T>
@end

MH_EXPORT __attribute__((unavailable(
    "Use NSExpression instead, applying the mgl_step:from:stops: or "
    "mgl_interpolate:withCurveType:parameters:stops: function to the $zoomLevel variable.")))
@interface MHCameraStyleFunction<T> : MHStyleFunction<T>
@end

MH_EXPORT __attribute__((unavailable(
    "Use NSExpression instead, applying the mgl_step:from:stops: or "
    "mgl_interpolate:withCurveType:parameters:stops: function to a key path expression.")))
@interface MHSourceStyleFunction<T> : MHStyleFunction<T>
@end

MH_EXPORT
__attribute__((unavailable("Use a NSExpression instead with nested mgl_step:from:stops: or "
                           "mgl_interpolate:withCurveType:parameters:stops: function calls.")))
@interface MHCompositeStyleFunction<T> : MHStyleFunction<T>
@end

NS_ASSUME_NONNULL_END
