#import "LocationCoordinate2DTransformer.h"

#import <Mapbox.h>

@implementation LocationCoordinate2DTransformer {
    MHCoordinateFormatter *_coordinateFormatter;
}

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (instancetype)init {
    if (self = [super init]) {
        _coordinateFormatter = [[MHCoordinateFormatter alloc] init];
    }
    return self;
}

- (id)transformedValue:(id)value {
    if (![value isKindOfClass:[NSValue class]]) {
        return nil;
    }
    return [_coordinateFormatter stringForObjectValue:value].capitalizedString;
}

@end
