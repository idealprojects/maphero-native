#import "MHMapViewIntegrationTest.h"
#import "MHTestUtility.h"
#import "../../../darwin/src/MHGeometry_Private.h"

#include <mbgl/map/camera.hpp>

@interface MHCameraTransitionFinishTests : MHMapViewIntegrationTest
@end

@implementation MHCameraTransitionFinishTests

- (void)testEaseToCompletionHandler {
    
    MHCoordinateBounds bounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(0.0, 0.0),
                                                         CLLocationCoordinate2DMake(1.0, 1.0));
    MHMapCamera *camera = [self.mapView cameraThatFitsCoordinateBounds:bounds];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion block should be called"];
    
    [self.mapView setCamera:camera
               withDuration:0.0
    animationTimingFunction:nil
          completionHandler:^{
              [expectation fulfill];
          }];
    
    [self waitForExpectations:@[expectation] timeout:0.5];
}

- (void)testEaseToCompletionHandlerAnimated {
    
    MHCoordinateBounds bounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(0.0, 0.0),
                                                         CLLocationCoordinate2DMake(1.0, 1.0));
    MHMapCamera *camera = [self.mapView cameraThatFitsCoordinateBounds:bounds];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion block should be called"];
    
    [self.mapView setCamera:camera
               withDuration:0.3
    animationTimingFunction:nil
          completionHandler:^{
              [expectation fulfill];
          }];
    
    [self waitForExpectations:@[expectation] timeout:0.5];
}

- (void)testFlyToCompletionHandler {
    
    MHCoordinateBounds bounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(0.0, 0.0),
                                                         CLLocationCoordinate2DMake(1.0, 1.0));
    MHMapCamera *camera = [self.mapView cameraThatFitsCoordinateBounds:bounds];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion block should be called"];
    
    [self.mapView flyToCamera:camera
                 withDuration:0.0
            completionHandler:^{
                [expectation fulfill];
            }];
    
    [self waitForExpectations:@[expectation] timeout:0.5];
}

- (void)testFlyToCompletionHandlerAnimated {
    
    MHCoordinateBounds bounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(0.0, 0.0),
                                                         CLLocationCoordinate2DMake(1.0, 1.0));
    MHMapCamera *camera = [self.mapView cameraThatFitsCoordinateBounds:bounds];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion block should be called"];
    
    [self.mapView flyToCamera:camera
                 withDuration:0.3
            completionHandler:^{
                [expectation fulfill];
            }];
    
    [self waitForExpectations:@[expectation] timeout:0.5];
}
@end

// MARK: - camera transitions with NaN values

@interface MHMapView (MHCameraTransitionFinishNaNTests)
- (mbgl::CameraOptions)cameraOptionsObjectForAnimatingToCamera:(MHMapCamera *)camera edgePadding:(UIEdgeInsets)insets;
@end

@interface MHCameraTransitionNaNZoomMapView: MHMapView
@end

@implementation MHCameraTransitionNaNZoomMapView
- (mbgl::CameraOptions)cameraOptionsObjectForAnimatingToCamera:(MHMapCamera *)camera edgePadding:(UIEdgeInsets)insets {
    mbgl::CameraOptions options = [super cameraOptionsObjectForAnimatingToCamera:camera edgePadding:insets];
    options.zoom = NAN;
    return options;
}
@end

// Subclass the entire test suite, but with a different MHMapView subclass
@interface MHCameraTransitionFinishNaNTests : MHCameraTransitionFinishTests
@end

@implementation MHCameraTransitionFinishNaNTests
- (MHMapView *)mapViewForTestWithFrame:(CGRect)rect styleURL:(NSURL *)styleURL {
    return [[MHCameraTransitionNaNZoomMapView alloc] initWithFrame:rect styleURL:styleURL];
}
@end

