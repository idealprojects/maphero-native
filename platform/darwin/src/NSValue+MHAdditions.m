#import "NSValue+MHAdditions.h"

@implementation NSValue (MHAdditions)

// MARK: Geometry

+ (instancetype)valueWithMHCoordinate:(CLLocationCoordinate2D)coordinate {
    return [self valueWithBytes:&coordinate objCType:@encode(CLLocationCoordinate2D)];
}

- (CLLocationCoordinate2D)MHCoordinateValue {
    CLLocationCoordinate2D coordinate;
    [self getValue:&coordinate];
    return coordinate;
}

+ (instancetype)valueWithMHMapPoint:(MHMapPoint)point {
    return [self valueWithBytes:&point objCType:@encode(MHMapPoint)];
}

-(MHMapPoint) MHMapPointValue {
    MHMapPoint point;
    [self getValue:&point];
    return point;
}

+ (instancetype)valueWithMHCoordinateSpan:(MHCoordinateSpan)span {
    return [self valueWithBytes:&span objCType:@encode(MHCoordinateSpan)];
}

- (MHCoordinateSpan)MHCoordinateSpanValue {
    MHCoordinateSpan span;
    [self getValue:&span];
    return span;
}

+ (instancetype)valueWithMHCoordinateBounds:(MHCoordinateBounds)bounds {
    return [self valueWithBytes:&bounds objCType:@encode(MHCoordinateBounds)];
}

- (MHCoordinateBounds)MHCoordinateBoundsValue {
    MHCoordinateBounds bounds;
    [self getValue:&bounds];
    return bounds;
}

+ (instancetype)valueWithMHCoordinateQuad:(MHCoordinateQuad)quad {
    return [self valueWithBytes:&quad objCType:@encode(MHCoordinateQuad)];
}

- (MHCoordinateQuad)MHCoordinateQuadValue {
    MHCoordinateQuad quad;
    [self getValue:&quad];
    return quad;
}

// MARK: Offline maps

+ (NSValue *)valueWithMHOfflinePackProgress:(MHOfflinePackProgress)progress {
    return [NSValue value:&progress withObjCType:@encode(MHOfflinePackProgress)];
}

- (MHOfflinePackProgress)MHOfflinePackProgressValue {
    MHOfflinePackProgress progress;
    [self getValue:&progress];
    return progress;
}

// MARK: Working with Transition Values

+ (NSValue *)valueWithMHTransition:(MHTransition)transition {
    return [NSValue value:&transition withObjCType:@encode(MHTransition)];
}

- (MHTransition)MHTransitionValue {
    MHTransition transition;
    [self getValue:&transition];
    return transition;
}

+ (NSValue *)valueWithMHSphericalPosition:(MHSphericalPosition)lightPosition
{
    return [NSValue value:&lightPosition withObjCType:@encode(MHSphericalPosition)];
}

- (MHSphericalPosition)MHSphericalPositionValue
{
    MHSphericalPosition lightPosition;
    [self getValue:&lightPosition];
    return lightPosition;
}

+ (NSValue *)valueWithMHLightAnchor:(MHLightAnchor)lightAnchor {
    return [NSValue value:&lightAnchor withObjCType:@encode(MHLightAnchor)];
}

- (MHLightAnchor)MHLightAnchorValue
{
    MHLightAnchor achorType;
    [self getValue:&achorType];
    return achorType;
}

@end
