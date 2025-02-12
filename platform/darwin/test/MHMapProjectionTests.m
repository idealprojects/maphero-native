#import <Mapbox.h>
#import <XCTest/XCTest.h>
#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
    #define MHEdgeInsets UIEdgeInsets
    #define MHEdgeInsetsMake UIEdgeInsetsMake
#else
    #define MHEdgeInsets NSEdgeInsets
    #define MHEdgeInsetsMake NSEdgeInsetsMake
#endif

@interface MHMapProjectionTests : XCTestCase

@property (nonatomic, retain) MHMapView *mapView;
@property (nonatomic, retain) MHMapProjection *mapProjection;

@end

@implementation MHMapProjectionTests

- (void)setUp {
    [super setUp];

    [MHSettings setApiKey:@"pk.feedcafedeadbeefbadebede"];
    NSURL *styleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"one-liner" withExtension:@"json"];
    self.mapView = [[MHMapView alloc] initWithFrame:CGRectMake(0, 0, 200, 200) styleURL:styleURL];

    [self.mapView setVisibleCoordinateBounds:MHCoordinateBoundsMake(CLLocationCoordinate2DMake(1.0, 1.0),
                                                                     CLLocationCoordinate2DMake(2.0, 2.0))];

    self.mapProjection = self.mapView.mapProjection;
}

- (void)tearDown {
    self.mapView = nil;
    self.mapProjection = nil;
    [MHSettings setApiKey:nil];

    [super tearDown];
}

- (void)testMapProjectionCamera {
    XCTAssertTrue([self.mapProjection.camera isEqualToMapCamera:self.mapView.camera],
                  @"Map projection camera must be equal to the map view's one");
}

- (void)testMapProjectionCameraSet {
    MHCoordinateBounds newBounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(3.0, 3.0),
                                                            CLLocationCoordinate2DMake(4.0, 4.0));
    MHEdgeInsets paddings = MHEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);

    MHMapCamera *newCamera = [self.mapView cameraThatFitsCoordinateBounds:newBounds edgePadding:paddings];
    [self.mapProjection setCamera:newCamera withEdgeInsets:paddings];

    XCTAssertTrue([self.mapProjection.camera isEqualToMapCamera:newCamera],
                  @"Map projection camera must be equal to the one just set");

    CLLocationCoordinate2D topLeftCoordinate = [self.mapProjection convertPoint:CGPointMake(10.0, 10.0)];
    XCTAssertEqualWithAccuracy(topLeftCoordinate.latitude, 4.0, 1e-3);
    XCTAssertEqualWithAccuracy(topLeftCoordinate.longitude, 3.0, 1e-3);

    CLLocationCoordinate2D bottomRightCoordinate = [self.mapProjection convertPoint:CGPointMake(190.0, 190.0)];
    XCTAssertEqualWithAccuracy(bottomRightCoordinate.latitude, 3.0, 1e-3);
    XCTAssertEqualWithAccuracy(bottomRightCoordinate.longitude, 4.0, 1e-3);

    CLLocationCoordinate2D centerCoordinate = [self.mapProjection convertPoint:CGPointMake(100.0, 100.0)];
    XCTAssertEqualWithAccuracy(centerCoordinate.latitude, 3.5, 1e-3);
    XCTAssertEqualWithAccuracy(centerCoordinate.longitude, 3.5, 1e-3);
}

- (void)testMapProjectionVisibleBoundsSet {
    MHCoordinateBounds newBounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(3.0, 3.0),
                                                            CLLocationCoordinate2DMake(4.0, 4.0));
    MHEdgeInsets paddings = MHEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);

    [self.mapProjection setVisibleCoordinateBounds:newBounds edgePadding:paddings];

    CLLocationCoordinate2D topLeftCoordinate = [self.mapProjection convertPoint:CGPointMake(10.0, 10.0)];
    XCTAssertEqualWithAccuracy(topLeftCoordinate.latitude, 4.0, 1e-3);
    XCTAssertEqualWithAccuracy(topLeftCoordinate.longitude, 3.0, 1e-3);

    CLLocationCoordinate2D bottomRightCoordinate = [self.mapProjection convertPoint:CGPointMake(190.0, 190.0)];
    XCTAssertEqualWithAccuracy(bottomRightCoordinate.latitude, 3.0, 1e-3);
    XCTAssertEqualWithAccuracy(bottomRightCoordinate.longitude, 4.0, 1e-3);

    CLLocationCoordinate2D centerCoordinate = [self.mapProjection convertPoint:CGPointMake(100.0, 100.0)];
    XCTAssertEqualWithAccuracy(centerCoordinate.latitude, 3.5, 1e-3);
    XCTAssertEqualWithAccuracy(centerCoordinate.longitude, 3.5, 1e-3);
}

@end
