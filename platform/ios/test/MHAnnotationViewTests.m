#import <Mapbox.h>
#import <XCTest/XCTest.h>
#import "MHTestUtility.h"

static NSString * const MHTestAnnotationReuseIdentifer = @"MHTestAnnotationReuseIdentifer";


@interface MHMapView (Tests)
@property (nonatomic) MHCameraChangeReason cameraChangeReasonBitmask;
@end



@interface MHCustomAnnotationView : MHAnnotationView

@end

@implementation MHCustomAnnotationView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    return [super initWithReuseIdentifier:@"reuse-id"];
}

@end

@interface MHAnnotationView (Test)

@property (nonatomic) MHMapView *mapView;
@property (nonatomic, readwrite) MHAnnotationViewDragState dragState;
- (void)setDragState:(MHAnnotationViewDragState)dragState;

@end

@interface MHMapView (Test)
@property (nonatomic) UIView<MHCalloutView> *calloutViewForSelectedAnnotation;
@end

@interface MHTestAnnotation : NSObject <MHAnnotation>
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@end

@implementation MHTestAnnotation
@end

@interface MHTestCalloutView: UIView<MHCalloutView>
@property (nonatomic) BOOL didCallDismissCalloutAnimated;
@property (nonatomic, strong) id <MHAnnotation> representedObject;
@property (nonatomic, strong) UIView *leftAccessoryView;
@property (nonatomic, strong) UIView *rightAccessoryView;
@property (nonatomic, weak) id<MHCalloutViewDelegate> delegate;
@end

@implementation MHTestCalloutView

- (void)dismissCalloutAnimated:(BOOL)animated
{
    _didCallDismissCalloutAnimated = YES;
}

- (void)presentCalloutFromRect:(CGRect)rect inView:(nonnull UIView *)view constrainedToRect:(CGRect)constrainedRect animated:(BOOL)animated {}

@end

@interface MHAnnotationViewTests : XCTestCase <MHMapViewDelegate>
@property (nonatomic) XCTestExpectation *expectation;
@property (nonatomic) MHMapView *mapView;
@property (nonatomic, weak) MHAnnotationView *annotationView;
@property (nonatomic) NSInteger annotationSelectedCount;
@property (nonatomic) void (^prepareAnnotationView)(MHAnnotationView*);
@end

@implementation MHAnnotationViewTests

- (void)setUp
{
    [super setUp];
    _mapView = [[MHMapView alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
    _mapView.delegate = self;
}

- (void)testAnnotationView
{
    _expectation = [self expectationWithDescription:@"annotation property"];

    MHTestAnnotation *annotation = [[MHTestAnnotation alloc] init];
    [_mapView addAnnotation:annotation];

    [self waitForExpectationsWithTimeout:5 handler:nil];

    XCTAssert(_mapView.annotations.count == 1, @"number of annotations should be 1");
    XCTAssertNotNil(_annotationView.annotation, @"annotation property should not be nil");
    XCTAssertNotNil(_annotationView.mapView, @"mapView property should not be nil");

    MHTestCalloutView *testCalloutView = [[MHTestCalloutView  alloc] init];
    _mapView.calloutViewForSelectedAnnotation = testCalloutView;
    _annotationView.dragState = MHAnnotationViewDragStateStarting;
    XCTAssertTrue(testCalloutView.didCallDismissCalloutAnimated, @"callout view was not dismissed");

    [_mapView removeAnnotation:_annotationView.annotation];

    XCTAssert(_mapView.annotations.count == 0, @"number of annotations should be 0");
    XCTAssertNil(_annotationView.annotation, @"annotation property should be nil");
}

- (void)testCustomAnnotationView
{
    MHCustomAnnotationView *customAnnotationView = [[MHCustomAnnotationView alloc] initWithReuseIdentifier:@"reuse-id"];
    XCTAssertNotNil(customAnnotationView);
}

- (void)testSelectingOffscreenAnnotation
{
    // Partial test for https://github.com/mapbox/mapbox-gl-native/issues/9790

    // This isn't quite the same as in updateAnnotationViews, but should be sufficient for this test.
    MHCoordinateBounds coordinateBounds = [_mapView convertRect:_mapView.bounds toCoordinateBoundsFromView:_mapView];

    // -90 latitude is invalid. TBD.
    BOOL anyOffscreen = NO;
    NSInteger selectionCount = 0;

    for (NSInteger latitude = -89; latitude <= 90; latitude += 10)
    {
        for (NSInteger longitude = -180; longitude <= 180; longitude += 10)
        {
            MHTestAnnotation *annotation = [[MHTestAnnotation alloc] init];

            annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
            [_mapView addAnnotation:annotation];

            if (!(MHCoordinateInCoordinateBounds(annotation.coordinate, coordinateBounds)))
                anyOffscreen = YES;

            XCTAssertNil(_mapView.selectedAnnotations.firstObject, @"There should be no selected annotation");

            // First selection
            [_mapView selectAnnotation:annotation animated:NO completionHandler:nil];
            selectionCount++;

            XCTAssert(_mapView.selectedAnnotations.count == 1, @"There should only be 1 selected annotation");
            XCTAssertEqualObjects(_mapView.selectedAnnotations.firstObject, annotation, @"The annotation should be selected");

            // Deselect
            [_mapView deselectAnnotation:annotation animated:NO];
            XCTAssert(_mapView.selectedAnnotations.count == 0, @"There should be no selected annotations");

            // Second selection
            _mapView.selectedAnnotations = @[annotation];
            selectionCount++;

            XCTAssert(_mapView.selectedAnnotations.count == 1, @"There should be 1 selected annotation");
            XCTAssertEqualObjects(_mapView.selectedAnnotations.firstObject, annotation, @"The annotation should be selected");

            // Deselect
            [_mapView deselectAnnotation:annotation animated:NO];
            XCTAssert(_mapView.selectedAnnotations.count == 0, @"There should be no selected annotations");
        }
    }

    XCTAssert(anyOffscreen, @"At least one of these annotations should be offscreen");
    XCTAssertEqual(selectionCount, self.annotationSelectedCount, @"-mapView:didSelectAnnotation: should be called for each selection");
}

- (void)testSelectingOnscreenAnnotationThatHasNotBeenAdded {
    // See https://github.com/mapbox/mapbox-gl-native/issues/11476

    // This bug occurs under the following conditions:
    //
    // - There are content insets (e.g. navigation bar) for the compare against
    //      CGRectZero (now CGRectNull)
    // - annotationView.enabled == NO - Currently this can happen if you use
    //      `-initWithFrame:` rather than one of the provided initializers
    //

    self.prepareAnnotationView = ^(MHAnnotationView *view) {
        view.enabled = NO;
    };

    self.mapView.contentInset = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);

    MHCameraChangeReason reasonBefore = self.mapView.cameraChangeReasonBitmask;
    XCTAssert(reasonBefore == MHCameraChangeReasonNone, @"Camera should not have moved at start of test");

    // Create annotation
    MHPointFeatureClusterFeature *point = [[MHPointFeatureClusterFeature alloc] init];
    point.title = NSStringFromSelector(_cmd);
    point.coordinate = CLLocationCoordinate2DMake(0.0, 0.0);

    MHCoordinateBounds coordinateBounds = [self.mapView convertRect:self.mapView.bounds toCoordinateBoundsFromView:self.mapView];
    XCTAssert(MHCoordinateInCoordinateBounds(point.coordinate, coordinateBounds), @"The test point should be within the visible map view");

    // Select on screen annotation (DO NOT ADD FIRST).
    [self.mapView selectAnnotation:point animated:YES completionHandler:nil];

    // Expect - the camera NOT to move.
    MHCameraChangeReason reasonAfter = self.mapView.cameraChangeReasonBitmask;
    XCTAssert(reasonAfter == MHCameraChangeReasonNone, @"Camera should not have moved");
}

- (void)checkDefaultPropertiesForAnnotationView:(MHAnnotationView*)view {
    XCTAssertNil(view.annotation);
    XCTAssertNil(view.reuseIdentifier);
    XCTAssertEqual(view.centerOffset.dx, 0.0);
    XCTAssertEqual(view.centerOffset.dy, 0.0);
    XCTAssertFalse(view.scalesWithViewingDistance);
    XCTAssertFalse(view.rotatesToMatchCamera);
    XCTAssertFalse(view.isSelected);
    XCTAssert(view.isEnabled);
    XCTAssertFalse(view.isDraggable);
    XCTAssertEqual(view.dragState, MHAnnotationViewDragStateNone);
}

- (void)testAnnotationViewInitWithFramePENDING {
    MH_CHECK_IF_PENDING_TEST_SHOULD_RUN();
    CGRect frame = CGRectMake(10.0, 10.0, 100.0, 100.0);
    MHAnnotationView *view = [[MHAnnotationView alloc] initWithFrame:frame];
    [self checkDefaultPropertiesForAnnotationView:view];
}

- (void)testAnnotationViewInitWithReuseIdentifier {
    MHAnnotationView *view = [[MHAnnotationView alloc] initWithReuseIdentifier:nil];
    [self checkDefaultPropertiesForAnnotationView:view];
}

- (void)testSelectingADisabledAnnotationViewPENDING {
    MH_CHECK_IF_PENDING_TEST_SHOULD_RUN();
    self.prepareAnnotationView = ^(MHAnnotationView *view) {
        view.enabled = NO;
    };

    // Create annotation
    MHPointFeatureClusterFeature *point = [[MHPointFeatureClusterFeature alloc] init];
    point.title = NSStringFromSelector(_cmd);
    point.coordinate = CLLocationCoordinate2DMake(0.0, 0.0);
    
    XCTAssert(self.mapView.selectedAnnotations.count == 0, @"There should be 0 selected annotations");
    
    [self.mapView selectAnnotation:point animated:NO completionHandler:nil];
    
    XCTAssert(self.mapView.selectedAnnotations.count == 0, @"There should be 0 selected annotations");
}

// MARK: - MHMapViewDelegate -

- (MHAnnotationView *)mapView:(MHMapView *)mapView viewForAnnotation:(id<MHAnnotation>)annotation
{
    MHAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:MHTestAnnotationReuseIdentifer];

    if (!annotationView)
    {
        annotationView = [[MHAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:MHTestAnnotationReuseIdentifer];
    }

    if (self.prepareAnnotationView) {
        self.prepareAnnotationView(annotationView);
    }

    _annotationView = annotationView;

    return annotationView;
}

- (void)mapView:(MHMapView *)mapView didAddAnnotationViews:(NSArray<MHAnnotationView *> *)annotationViews
{
    [_expectation fulfill];
}

- (void)mapView:(MHMapView *)mapView didSelectAnnotation:(id<MHAnnotation>)annotation
{
    self.annotationSelectedCount++;
}

@end
