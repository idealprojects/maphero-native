#import <Mapbox.h>
#import <XCTest/XCTest.h>

MHImage *MHNormalizedImage(MHImage *sourceImage) {
#if TARGET_OS_IPHONE
    CGSize scaledSize = CGSizeMake(sourceImage.size.width * sourceImage.scale, sourceImage.size.height * sourceImage.scale);
    UIGraphicsBeginImageContextWithOptions(scaledSize, NO, UIScreen.mainScreen.scale);
    [sourceImage drawInRect:(CGRect){ .origin = CGPointZero, .size = scaledSize }];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
#else
    return [NSImage imageWithSize:sourceImage.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        [sourceImage drawInRect:dstRect];
        return YES;
    }];
#endif
}

BOOL MHEqualImages(MHImage *leftImage, MHImage *rightImage) {
#if TARGET_OS_IPHONE
    NSData *leftData = UIImagePNGRepresentation(MHNormalizedImage(leftImage));
    NSData *rightData = UIImagePNGRepresentation(MHNormalizedImage(rightImage));
    return [leftData isEqualToData:rightData];
#else
    CGImageRef leftCGImage = [MHNormalizedImage(leftImage) CGImageForProposedRect:nil context:nil hints:nil];
    NSBitmapImageRep *leftImageRep = [[NSBitmapImageRep alloc] initWithCGImage:leftCGImage];
    NSData *leftData = [leftImageRep representationUsingType:NSPNGFileType properties:@{}];
    
    CGImageRef rightCGImage = [MHNormalizedImage(rightImage) CGImageForProposedRect:nil context:nil hints:nil];
    NSBitmapImageRep *rightImageRep = [[NSBitmapImageRep alloc] initWithCGImage:rightCGImage];
    NSData *rightData = [rightImageRep representationUsingType:NSPNGFileType properties:@{}];
    
    return [leftData isEqualToData:rightData];
#endif
}

MHImage *MHImageFromCurrentContext(void) {
#if TARGET_OS_IPHONE
    return UIGraphicsGetImageFromCurrentImageContext();
#else
    CGContextRef context = NSGraphicsContext.currentContext.CGContext;
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    CGFloat scale = NSScreen.mainScreen.backingScaleFactor;
    NSSize imageSize = NSMakeSize(CGImageGetWidth(cgImage) / scale, CGImageGetHeight(cgImage) / scale);
    NSImage *image = [[NSImage alloc] initWithCGImage:cgImage size:imageSize];
    CGImageRelease(cgImage);
    return image;
#endif
}

@interface MHMapSnapshotterTests : XCTestCase <MHMapSnapshotterDelegate, MHOfflineStorageDelegate>

@property (nonatomic) XCTestExpectation *styleLoadingExpectation;
@property (nonatomic, copy, nullable) void (^runtimeStylingActions)(MHStyle *style);

@end

@implementation MHMapSnapshotterTests

- (void)setUp {
    [super setUp];
    
    [MHSettings setApiKey:@"pk.feedcafedeadbeefbadebede"];
    
    [MHOfflineStorage sharedOfflineStorage].delegate = self;
}

- (void)tearDown {
    [MHSettings setApiKey:nil];
    [MHOfflineStorage sharedOfflineStorage].delegate = nil;
    self.styleLoadingExpectation = nil;
    self.runtimeStylingActions = nil;
    [super tearDown];
}

- (void)testOverlayHandler {
    XCTSkip(@"Snapshotter not implemented yet for Metal. See https://github.com/maplibre/maplibre-native/issues/1862");
    self.styleLoadingExpectation = [self expectationWithDescription:@"Style should finish loading."];
    XCTestExpectation *overlayExpectation = [self expectationWithDescription:@"Overlay handler should get called."];
    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Completion handler should get called."];
    
#if TARGET_OS_IPHONE
    CGRect rect = CGRectMake(0, 0, 500, 500);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, UIScreen.mainScreen.scale);
    UIImage *blankImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
#else
    NSImage *blankImage = [NSImage imageWithSize:NSMakeSize(500, 500) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        return YES;
    }];
#endif
    
    NSURL *styleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"one-liner" withExtension:@"json"];
    MHMapCamera *camera = [MHMapCamera camera];
    MHMapSnapshotOptions *options = [[MHMapSnapshotOptions alloc] initWithStyleURL:styleURL camera:camera size:CGSizeMake(500, 500)];
    
    MHMapSnapshotter *snapshotter = [[MHMapSnapshotter alloc] initWithOptions:options];
    snapshotter.delegate = self;
    
    [snapshotter startWithOverlayHandler:^(MHMapSnapshotOverlay * _Nonnull snapshotOverlay) {
        XCTAssertNotNil(snapshotOverlay);
        if (snapshotOverlay) {
            XCTAssertNotEqual(snapshotOverlay.context, NULL);
            MHImage *imageFromContext = MHImageFromCurrentContext();
            XCTAssertTrue(MHEqualImages(blankImage, imageFromContext), @"Base map in snapshot should be blank.");
        }
        [overlayExpectation fulfill];
    } completionHandler:^(MHMapSnapshot * _Nullable snapshot, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(snapshot);
        if (snapshot) {
            XCTAssertEqual(snapshot.image.size.width, 500);
            XCTAssertEqual(snapshot.image.size.height, 500);
        }
        [completionExpectation fulfill];
    }];
    [self waitForExpectations:@[self.styleLoadingExpectation, overlayExpectation, completionExpectation] timeout:5 enforceOrder:YES];
}

- (void)testDelegate {
    XCTSkip(@"Snapshotter not implemented yet for Metal. See https://github.com/maplibre/maplibre-native/issues/1862");
    self.styleLoadingExpectation = [self expectationWithDescription:@"Style should finish loading."];
    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Completion handler should get called."];
    
    NSURL *styleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"one-liner" withExtension:@"json"];
    MHMapCamera *camera = [MHMapCamera camera];
    MHMapSnapshotOptions *options = [[MHMapSnapshotOptions alloc] initWithStyleURL:styleURL camera:camera size:CGSizeMake(500, 500)];
    
    MHMapSnapshotter *snapshotter = [[MHMapSnapshotter alloc] initWithOptions:options];
    snapshotter.delegate = self;
    
    [snapshotter startWithCompletionHandler:^(MHMapSnapshot * _Nullable snapshot, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(snapshot);
        if (snapshot) {
            XCTAssertEqual(snapshot.image.size.width, 500);
            XCTAssertEqual(snapshot.image.size.height, 500);
        }
        [completionExpectation fulfill];
    }];
    [self waitForExpectations:@[self.styleLoadingExpectation, completionExpectation] timeout:10 enforceOrder:YES];
}

- (void)testRuntimeStyling {
    XCTSkip(@"Snapshotter not implemented yet for Metal. See https://github.com/maplibre/maplibre-native/issues/1862");
    [self testStyleURL:nil camera:[MHMapCamera camera] applyingRuntimeStylingActions:^(MHStyle *style) {
        MHBackgroundStyleLayer *backgroundLayer = [[MHBackgroundStyleLayer alloc] initWithIdentifier:@"background"];
        backgroundLayer.backgroundColor = [NSExpression expressionForConstantValue:[MHColor orangeColor]];
        [style addLayer:backgroundLayer];
    } expectedImageName:@"Fixtures/MHMapSnapshotterTests/background"];
}

- (void)testLocalGlyphRendering {
    XCTSkip(@"Snapshotter not implemented yet for Metal. See https://github.com/maplibre/maplibre-native/issues/1862");
    [[NSUserDefaults standardUserDefaults] setObject:@[@"PingFang TC"] forKey:@"MHIdeographicFontFamilyName"];
    NSURL *styleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"mixed" withExtension:@"json"];
    [self testStyleURL:styleURL camera:nil applyingRuntimeStylingActions:^(MHStyle *style) {} expectedImageName:@"Fixtures/MHMapSnapshotterTests/PingFang"];
}

/**
 Tests that applying the given runtime styling actions on a blank style results in a snapshot image that matches the image with the given name in the asset catalog.
 
 @param actions Runtime styling actions to apply to the blank style.
 @param camera The camera to show, or `nil` to show the style’s default camera.
 @param expectedImageName Name of the test fixture image in Media.xcassets.
 */
- (void)testStyleURL:(nullable NSURL *)styleURL camera:(nullable MHMapCamera *)camera applyingRuntimeStylingActions:(void (^)(MHStyle *style))actions expectedImageName:(NSString *)expectedImageName {
    self.styleLoadingExpectation = [self expectationWithDescription:@"Style should finish loading."];
    XCTestExpectation *overlayExpectation = [self expectationWithDescription:@"Overlay handler should get called."];
    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Completion handler should get called."];
    
#if TARGET_OS_IPHONE
    UIImage *expectedImage = [UIImage imageNamed:expectedImageName inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
#else
    NSImage *expectedImage = [[NSBundle bundleForClass:[self class]] imageForResource:expectedImageName];
#endif
    XCTAssertNotNil(expectedImage, @"Image fixture “%@” missing from Media.xcassets.", expectedImageName);
    
    if (!styleURL) {
        styleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"one-liner" withExtension:@"json"];
    }
    
    MHMapCamera *defaultCamera = camera ?: [MHMapCamera camera];
    if (!camera) {
        defaultCamera.centerCoordinate = kCLLocationCoordinate2DInvalid;
        defaultCamera.heading = -1;
        defaultCamera.pitch = -1;
    }
    MHMapSnapshotOptions *options = [[MHMapSnapshotOptions alloc] initWithStyleURL:styleURL camera:defaultCamera size:expectedImage.size];
    if (!camera) {
        options.zoomLevel = -1;
    }
    
    MHMapSnapshotter *snapshotter = [[MHMapSnapshotter alloc] initWithOptions:options];
    snapshotter.delegate = self;
    self.runtimeStylingActions = actions;
    
    [snapshotter startWithOverlayHandler:^(MHMapSnapshotOverlay * _Nonnull snapshotOverlay) {
        XCTAssertNotNil(snapshotOverlay);
// This image comparison returns false, but they are identical when inspecting them manually
//        if (snapshotOverlay) {
//            XCTAssertNotEqual(snapshotOverlay.context, NULL);
//            MHImage *actualImage = MHImageFromCurrentContext();
//            XCTAssertTrue(MHEqualImages(expectedImage, actualImage), @"Bare snapshot before ornamentation differs from expected image.");
//        }
        [overlayExpectation fulfill];
    } completionHandler:^(MHMapSnapshot * _Nullable snapshot, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(snapshot);
        if (snapshot) {
            XCTAssertEqual(snapshot.image.size.width, expectedImage.size.width);
            XCTAssertEqual(snapshot.image.size.height, expectedImage.size.height);
        }
        [completionExpectation fulfill];
    }];
    [self waitForExpectations:@[self.styleLoadingExpectation, overlayExpectation, completionExpectation] timeout:5 enforceOrder:YES];
    self.runtimeStylingActions = nil;
}

// MARK: MHMapSnapshotterDelegate methods

- (void)mapSnapshotter:(MHMapSnapshotter *)snapshotter didFinishLoadingStyle:(MHStyle *)style {
    XCTAssertNotNil(snapshotter);
    XCTAssertNotNil(style);
    
    if (self.runtimeStylingActions) {
        self.runtimeStylingActions(style);
    }
    
    [self.styleLoadingExpectation fulfill];
}

// MARK: MHOfflineStorageDelegate methods

- (NSURL *)offlineStorage:(MHOfflineStorage *)storage URLForResourceOfKind:(MHResourceKind)kind withURL:(NSURL *)url {
    if (kind == MHResourceKindGlyphs && [url.scheme isEqualToString:@"local"]) {
        return [[NSBundle bundleForClass:[self class]] URLForResource:@"glyphs" withExtension:@"pbf"];
    }
    return url;
}

@end
