#import <Mapbox.h>
#import <XCTest/XCTest.h>

#define MHConstantExpression(constant) [NSExpression expressionForConstantValue:constant]

@interface MHStyleLayerTests : XCTestCase <MHMapViewDelegate>

@property (nonatomic, copy, readonly, class) NSString *layerType;

- (void)testPropertyName:(NSString *)name isBoolean:(BOOL)isBoolean;

@end

@interface NSString (MHStyleLayerTestAdditions)

@property (nonatomic, readonly, copy) NSArray<NSString *> *lexicalClasses;
@property (nonatomic, readonly, copy) NSString *lemma;

@end

@interface NSValue (MHStyleLayerTestAdditions)

+ (instancetype)valueWithMHVector:(CGVector)vector;

@property (readonly) CGVector MHVectorValue;

@end
