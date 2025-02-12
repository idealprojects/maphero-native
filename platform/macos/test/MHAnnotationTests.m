#import <Mapbox/Mapbox.h>
#import <XCTest/XCTest.h>

@interface MHAnnotationTests : XCTestCase <MHMapViewDelegate>
@property (nonatomic) MHMapView *mapView;
@property (nonatomic) BOOL centerCoordinateDidChange;
@end

@implementation MHAnnotationTests

- (void)setUp
{
    [super setUp];
    _mapView = [[MHMapView alloc] initWithFrame:CGRectMake(0, 0, 256, 256)];
    _mapView.delegate = self;
}

- (void)testSelectingOnscreenAnnotationThatHasNotBeenAdded {
    // See https://github.com/mapbox/mapbox-gl-native/issues/11476

    // This bug occurs under the following conditions:
    //
    // - There are content insets (e.g. navigation bar) for the compare against
    //      NSZeroRect

    self.mapView.contentInsets = NSEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);

    // Create annotation
    MHPointFeature *point = [[MHPointFeature alloc] init];
    point.title = NSStringFromSelector(_cmd);
    point.coordinate = CLLocationCoordinate2DMake(0.0, 0.0);

    MHCoordinateBounds coordinateBounds = [self.mapView convertRect:self.mapView.bounds toCoordinateBoundsFromView:self.mapView];
    XCTAssert(MHCoordinateInCoordinateBounds(point.coordinate, coordinateBounds), @"The test point should be within the visible map view");

    [self.mapView addObserver:self forKeyPath:@"centerCoordinate" options:NSKeyValueObservingOptionNew context:_cmd];
    XCTAssertFalse(self.centerCoordinateDidChange, @"Center coordinate should not have changed at this point");

    // Select on screen annotation (DO NOT ADD FIRST).
    [self.mapView selectAnnotation:point];

    XCTAssertFalse(self.centerCoordinateDidChange, @"Center coordinate should not have changed after selecting a visible annotation");
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ((context == @selector(testSelectingOnscreenAnnotationThatHasNotBeenAdded)) &&
        (object == self.mapView)) {
        self.centerCoordinateDidChange = YES;
    }
}

@end
