#import "MHAttributedExpression.h"
#import "MHLoggingConfiguration_Private.h"

const MHAttributedExpressionKey MHFontNamesAttribute = @"text-font";
const MHAttributedExpressionKey MHFontScaleAttribute = @"font-scale";
const MHAttributedExpressionKey MHFontColorAttribute = @"text-color";

@implementation MHAttributedExpression

- (instancetype)initWithExpression:(NSExpression *)expression {
    self = [self initWithExpression:expression attributes:@{}];
    return self;
}

+ (instancetype)attributedExpression:(NSExpression *)expression fontNames:(nullable NSArray<NSString *> *)fontNames fontScale:(nullable NSNumber *)fontScale {
    MHAttributedExpression *attributedExpression;
    
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    
    if (fontNames && fontNames.count > 0) {
        attrs[MHFontNamesAttribute] = [NSExpression expressionForConstantValue:fontNames];
    }
    
    if (fontScale) {
        attrs[MHFontScaleAttribute] = [NSExpression expressionForConstantValue:fontScale];
    }
    
    attributedExpression = [[self alloc] initWithExpression:expression attributes:attrs];
    return attributedExpression;
}

+ (instancetype)attributedExpression:(NSExpression *)expression attributes:(nonnull NSDictionary<MHAttributedExpressionKey, NSExpression *> *)attrs {
    MHAttributedExpression *attributedExpression;
    
    attributedExpression = [[self alloc] initWithExpression:expression attributes:attrs];
    
    return attributedExpression;
}

- (instancetype)initWithExpression:(NSExpression *)expression attributes:(nonnull NSDictionary<MHAttributedExpressionKey, NSExpression *> *)attrs {
    if (self = [super init])
    {
        MHLogInfo(@"Starting %@ initialization.", NSStringFromClass([self class]));
        _expression = expression;
        _attributes = attrs;
        
        MHLogInfo(@"Finalizing %@ initialization.", NSStringFromClass([self class]));
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL result = NO;
    
    if ([object isKindOfClass:[self class]]) {
        MHAttributedExpression *otherObject = object;
        result = [self.expression isEqual:otherObject.expression] &&
        [_attributes isEqual:otherObject.attributes];
    }
    
    return result;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"MHAttributedExpression<Expression: %@ Attributes: %@>", self.expression, self.attributes];
}

@end
