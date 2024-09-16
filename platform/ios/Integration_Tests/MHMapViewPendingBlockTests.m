#import "MHMapViewIntegrationTest.h"
#import "MHTestUtility.h"

@interface MHMapView (MHMapViewPendingBlockTests)
@property (nonatomic) NSMutableArray *pendingCompletionBlocks;
- (void)stopDisplayLink;
@end

@interface MHMapViewPendingBlockTests : MHMapViewIntegrationTest
@property (nonatomic, copy) void (^observation)(NSDictionary*);
@property (nonatomic) BOOL completionHandlerCalled;
@end

@implementation MHMapViewPendingBlockTests

- (void)testSetCenterCoordinate {
    __typeof__(self) weakSelf = self;
    
    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            [strongSelf.mapView setCenterCoordinate:CLLocationCoordinate2DMake(10.0, 10.0)
                                          zoomLevel:10.0
                                          direction:0
                                           animated:NO
                                  completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:NSStringFromSelector(_cmd)
                                                    transition:transition
                                          addToPendingCallback:nil];
}

- (void)testSetCenterCoordinateAnimated {
    __typeof__(self) weakSelf = self;
    
    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            [strongSelf.mapView setCenterCoordinate:CLLocationCoordinate2DMake(10.0, 10.0)
                                          zoomLevel:10.0
                                          direction:0
                                           animated:YES
                                  completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:NSStringFromSelector(_cmd)
                                                    transition:transition
                                          addToPendingCallback:nil];
}

- (void)testSetVisibleCoordinateBounds {
    __typeof__(self) weakSelf = self;
    
    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            MHCoordinateBounds unitBounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(1, 1));
            [strongSelf.mapView setVisibleCoordinateBounds:unitBounds
                                               edgePadding:UIEdgeInsetsZero
                                                  animated:NO
                                         completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:NSStringFromSelector(_cmd)
                                                    transition:transition
                                          addToPendingCallback:nil];
}

- (void)testSetVisibleCoordinateBoundsAnimated {
    __typeof__(self) weakSelf = self;
    
    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            MHCoordinateBounds unitBounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(1, 1));
            [strongSelf.mapView setVisibleCoordinateBounds:unitBounds
                                               edgePadding:UIEdgeInsetsZero
                                                  animated:YES
                                         completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:NSStringFromSelector(_cmd)
                                                    transition:transition
                                          addToPendingCallback:nil];
}

- (void)testSetCamera {
    __typeof__(self) weakSelf = self;
    
    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            MHCoordinateBounds unitBounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(1, 1));
            MHMapCamera *camera = [strongSelf.mapView cameraThatFitsCoordinateBounds:unitBounds];
            
            [strongSelf.mapView setCamera:camera withDuration:0.0 animationTimingFunction:nil completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:NSStringFromSelector(_cmd)
                                                    transition:transition
                                          addToPendingCallback:nil];
}

- (void)testSetCameraAnimated {
    __typeof__(self) weakSelf = self;
    
    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            MHCoordinateBounds unitBounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(1, 1));
            MHMapCamera *camera = [strongSelf.mapView cameraThatFitsCoordinateBounds:unitBounds];
            
            [strongSelf.mapView setCamera:camera withDuration:0.3 animationTimingFunction:nil completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:NSStringFromSelector(_cmd)
                                                    transition:transition
                                          addToPendingCallback:nil];
}

- (void)testFlyToCamera {
    __typeof__(self) weakSelf = self;
    
    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            MHCoordinateBounds unitBounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(1, 1));
            MHMapCamera *camera = [strongSelf.mapView cameraThatFitsCoordinateBounds:unitBounds];
            
            [strongSelf.mapView flyToCamera:camera withDuration:0.0 completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:NSStringFromSelector(_cmd)
                                                    transition:transition
                                          addToPendingCallback:nil];
}

- (void)testFlyToCameraAnimated {
    
    __typeof__(self) weakSelf = self;

    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            MHCoordinateBounds unitBounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(1, 1));
            MHMapCamera *camera = [strongSelf.mapView cameraThatFitsCoordinateBounds:unitBounds];
            
            [strongSelf.mapView flyToCamera:camera withDuration:0.3 completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:NSStringFromSelector(_cmd)
                                                    transition:transition
                                          addToPendingCallback:nil];
}


// MARK: - test interrupting regular rendering

- (void)testSetCenterCoordinateSetHidden {
    
    __typeof__(self) weakSelf = self;
    
    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            [strongSelf.mapView setCenterCoordinate:CLLocationCoordinate2DMake(10.0, 10.0)
                                          zoomLevel:10.0
                                          direction:0
                                           animated:NO
                                  completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    dispatch_block_t addedToPending = ^{
        __typeof__(self) strongSelf = weakSelf;

        MHTestAssert(strongSelf, !strongSelf.completionHandlerCalled);
        
        // Now hide the mapview
        strongSelf.mapView.hidden = YES;
        
        MHTestAssert(strongSelf, strongSelf.completionHandlerCalled);
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:NSStringFromSelector(_cmd)
                                                    transition:transition
                                          addToPendingCallback:addedToPending];
}

- (void)testSetCenterCoordinatePauseRendering {
    
    __typeof__(self) weakSelf = self;
    
    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            [strongSelf.mapView setCenterCoordinate:CLLocationCoordinate2DMake(10.0, 10.0)
                                          zoomLevel:10.0
                                          direction:0
                                           animated:NO
                                  completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    dispatch_block_t addedToPending = ^{
        __typeof__(self) strongSelf = weakSelf;
        
        MHTestAssert(strongSelf, !strongSelf.completionHandlerCalled);
        
        // Stopping display link, should trigger the pending blocks
        [strongSelf.mapView stopDisplayLink];

        MHTestAssert(strongSelf, strongSelf.completionHandlerCalled);
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:NSStringFromSelector(_cmd)
                                                    transition:transition
                                          addToPendingCallback:addedToPending];
}

- (void)testSetCenterCoordinateRemoveFromSuperview {
    
    __typeof__(self) weakSelf = self;
    
    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            [strongSelf.mapView setCenterCoordinate:CLLocationCoordinate2DMake(10.0, 10.0)
                                          zoomLevel:10.0
                                          direction:0
                                           animated:NO
                                  completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    dispatch_block_t addedToPending = ^{
        __typeof__(self) strongSelf = weakSelf;
        
        MHTestAssert(strongSelf, !strongSelf.completionHandlerCalled);
        
        // Remove from window, triggering validateDisplayLink
        [strongSelf.mapView removeFromSuperview];
        
        MHTestAssert(strongSelf, strongSelf.completionHandlerCalled);
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:NSStringFromSelector(_cmd)
                                                    transition:transition
                                          addToPendingCallback:addedToPending];
}

// MARK: - Shared utility methods

- (void)internalTestCompletionBlockAddedToPendingForTestName:(NSString *)testName
                                                  transition:(void (^)(dispatch_block_t))transition
                                        addToPendingCallback:(dispatch_block_t)addToPendingCallback {
    
    XCTestExpectation *expectation = [self expectationWithDescription:testName];
    
    __weak __typeof__(self) myself = self;
    
    dispatch_block_t block = ^{
        myself.completionHandlerCalled = YES;
        [expectation fulfill];
    };
    
    XCTAssertNotNil(transition);
    transition(block);
    
    XCTAssert(!self.completionHandlerCalled);
    XCTAssert(self.mapView.pendingCompletionBlocks.count == 0);
    
    __block BOOL blockAddedToPendingBlocks = NO;
    
    // Observes changes to pendingCompletionBlocks (including additions)
    self.observation = ^(NSDictionary *change){

        NSLog(@"change = %@ count = %lu", change, (unsigned long)myself.mapView.pendingCompletionBlocks.count);

        NSArray *value = change[NSKeyValueChangeNewKey];
        
        MHTestAssert(myself, [value isKindOfClass:[NSArray class]]);
        
        if (value.count > 0) {
            MHTestAssert(myself, [value containsObject:block]);            
            MHTestAssert(myself, !blockAddedToPendingBlocks);
            if ([myself.mapView.pendingCompletionBlocks containsObject:block]) {
                blockAddedToPendingBlocks = YES;
                
                if (addToPendingCallback) {
                    addToPendingCallback();
                }
            }
        }
    };
    
    [self.mapView addObserver:self forKeyPath:@"pendingCompletionBlocks" options:NSKeyValueObservingOptionNew context:_cmd];
    
    [self waitForExpectations:@[expectation] timeout:0.5];
    
    XCTAssert(blockAddedToPendingBlocks);
    XCTAssert(self.completionHandlerCalled);
    XCTAssert(self.mapView.pendingCompletionBlocks.count == 0);
    
    [self.mapView removeObserver:self forKeyPath:@"pendingCompletionBlocks" context:_cmd];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (self.observation) {
        self.observation(change);
    }
}
@end
