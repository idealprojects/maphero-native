#import "MHIntegrationTestCase.h"

@interface MHMapViewIntegrationTest : MHIntegrationTestCase <MHMapViewDelegate>
@property (nonatomic) MHMapView *mapView;
@property (nonatomic) UIWindow *window;
@property (nonatomic) MHStyle *style;
@property (nonatomic) XCTestExpectation *styleLoadingExpectation;
@property (nonatomic) XCTestExpectation *renderFinishedExpectation;
@property (nonatomic) MHAnnotationView * (^viewForAnnotation)
    (MHMapView *mapView, id<MHAnnotation> annotation);
@property (nonatomic) void (^regionWillChange)(MHMapView *mapView, BOOL animated);
@property (nonatomic) void (^regionIsChanging)(MHMapView *mapView);
@property (nonatomic) void (^regionDidChange)
    (MHMapView *mapView, MHCameraChangeReason reason, BOOL animated);
@property (nonatomic) CGPoint (^mapViewUserLocationAnchorPoint)(MHMapView *mapView);
@property (nonatomic) BOOL (^mapViewAnnotationCanShowCalloutForAnnotation)
    (MHMapView *mapView, id<MHAnnotation> annotation);
@property (nonatomic) id<MHCalloutView> (^mapViewCalloutViewForAnnotation)
    (MHMapView *mapView, id<MHAnnotation> annotation);

// Utility methods
- (void)waitForMapViewToFinishLoadingStyleWithTimeout:(NSTimeInterval)timeout;
- (void)waitForMapViewToBeRenderedWithTimeout:(NSTimeInterval)timeout;
- (MHMapView *)mapViewForTestWithFrame:(CGRect)rect styleURL:(NSURL *)styleURL;
@end
