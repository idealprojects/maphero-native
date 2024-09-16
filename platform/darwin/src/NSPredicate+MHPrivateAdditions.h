#import <Foundation/Foundation.h>

#import "NSPredicate+MHAdditions.h"

#include <mbgl/style/filter.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface NSPredicate (MHPrivateAdditions)

- (mbgl::style::Filter)mgl_filter;

+ (nullable instancetype)mgl_predicateWithFilter:(mbgl::style::Filter)filter;

@end

@interface NSPredicate (MHExpressionAdditions)

- (nullable id)mgl_if:(id)firstValue, ...;

- (nullable id)mgl_match:(NSExpression *)firstCase, ...;

@end

NS_ASSUME_NONNULL_END
