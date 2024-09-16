#import <Mapbox/Mapbox.h>
#import <XCTest/XCTest.h>
#import "MHTestUtility.h"

#define MHTestFail(myself, ...) _XCTPrimitiveFail(myself, __VA_ARGS__)

#define MHTestAssert(myself, expression, ...) \
  _XCTPrimitiveAssertTrue(myself, expression, @ #expression, __VA_ARGS__)

#define MHTestAssertEqualWithAccuracy(myself, expression1, expression2, accuracy, ...)  \
  _XCTPrimitiveAssertEqualWithAccuracy(myself, expression1, @ #expression1, expression2, \
                                       @ #expression2, accuracy, @ #accuracy, __VA_ARGS__)
#define MHTestAssertNil(myself, expression, ...) \
  _XCTPrimitiveAssertNil(myself, expression, @ #expression, __VA_ARGS__)

#define MHTestAssertNotNil(myself, expression, ...) \
  _XCTPrimitiveAssertNotNil(myself, expression, @ #expression, __VA_ARGS__)

#define MHTestWarning(expression, format, ...)                                              \
  ({                                                                                         \
    if (!(expression)) {                                                                     \
      NSString *message = [NSString stringWithFormat:format, ##__VA_ARGS__];                 \
      printf("warning: Test Case '%s' at line %d: '%s' %s\n", __PRETTY_FUNCTION__, __LINE__, \
             #expression, message.UTF8String);                                               \
    }                                                                                        \
  })

@interface MHIntegrationTestCase : XCTestCase
@end
