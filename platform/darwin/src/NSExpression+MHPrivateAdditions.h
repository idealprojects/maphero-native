#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import "NSExpression+MHAdditions.h"

#include <mbgl/style/filter.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (MHExpressionAdditions)

- (nullable NSNumber *)mgl_number;
- (nullable NSNumber *)mgl_numberWithFallbackValues:(id)fallbackValue,
                                                    ... NS_REQUIRES_NIL_TERMINATION;

@end

@interface NSExpression (MHPrivateAdditions)

@property (nonatomic, readonly) mbgl::Value mgl_constantMBGLValue;
@property (nonatomic, readonly) std::vector<mbgl::Value> mgl_aggregateMBGLValue;
@property (nonatomic, readonly) mbgl::FeatureType mgl_featureType;
@property (nonatomic, readonly) std::vector<mbgl::FeatureType> mgl_aggregateFeatureType;
@property (nonatomic, readonly) mbgl::FeatureIdentifier mgl_featureIdentifier;
@property (nonatomic, readonly) std::vector<mbgl::FeatureIdentifier> mgl_aggregateFeatureIdentifier;

@end

@interface NSNull (MHExpressionAdditions)

@property (nonatomic, readonly) id mgl_jsonExpressionObject;

@end

@interface NSString (MHExpressionAdditions)

@property (nonatomic, readonly) id mgl_jsonExpressionObject;

@end

@interface NSNumber (MHExpressionAdditions)

- (id)mgl_interpolateWithCurveType:(NSString *)curveType
                        parameters:(NSArray *)parameters
                             stops:(NSDictionary<NSNumber *, id> *)stops;
- (id)mgl_stepWithMinimum:(id)minimum stops:(NSDictionary<NSNumber *, id> *)stops;

@property (nonatomic, readonly) id mgl_jsonExpressionObject;

@end

@interface NSArray (MHExpressionAdditions)

@property (nonatomic, readonly) id mgl_jsonExpressionObject;

@end

@interface NSDictionary (MHExpressionAdditions)

@property (nonatomic, readonly) id mgl_jsonExpressionObject;

- (id)mgl_has:(id)element;

@end

@interface MHColor (MHExpressionAdditions)

@property (nonatomic, readonly) id mgl_jsonExpressionObject;

@end

@interface NSExpression (MHExpressionAdditions)

- (NSExpression *)mgl_expressionWithContext:(NSDictionary<NSString *, NSExpression *> *)context;

- (id)mgl_has:(id)element;

@end

FOUNDATION_EXTERN NSArray *MHSubexpressionsWithJSONObjects(NSArray *objects);

NS_ASSUME_NONNULL_END
