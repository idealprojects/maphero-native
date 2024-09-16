#import "MHMapSnapshotter.h"

#import <mbgl/actor/actor.hpp>
#import <mbgl/actor/scheduler.hpp>
#import <mbgl/util/geo.hpp>
#import <mbgl/map/map_options.hpp>
#import <mbgl/map/map_snapshotter.hpp>
#import <mbgl/map/camera.hpp>
#import <mbgl/storage/resource_options.hpp>
#import <mbgl/util/client_options.hpp>
#import <mbgl/util/string.hpp>

#import "MHOfflineStorage_Private.h"
#import "MHGeometry_Private.h"
#import "MHStyle_Private.h"
#import "MHAttributionInfo_Private.h"
#import "MHLoggingConfiguration_Private.h"
#import "MHRendererConfiguration.h"
#import "MHMapSnapshotter_Private.h"
#import "MHSettings_Private.h"

#if TARGET_OS_IPHONE
#import "UIImage+MHAdditions.h"
#else
#import "NSImage+MHAdditions.h"
#import <CoreGraphics/CoreGraphics.h>
#import <CoreImage/CIContext.h>
#import <CoreImage/CIFilter.h>
#import <QuartzCore/QuartzCore.h>
#endif

#import "NSBundle+MHAdditions.h"

const CGPoint MHLogoImagePosition = CGPointMake(8, 8);
const CGFloat MHSnapshotterMinimumPixelSize = 64;

MHImage *MHAttributedSnapshot(mbgl::MapSnapshotter::Attributions attributions, MHImage *mglImage, mbgl::MapSnapshotter::PointForFn pointForFn, mbgl::MapSnapshotter::LatLngForFn latLngForFn, MHMapSnapshotOptions *options, MHMapSnapshotOverlayHandler overlayHandler);
MHMapSnapshot *MHSnapshotWithDecoratedImage(MHImage *mglImage, MHMapSnapshotOptions *options, mbgl::MapSnapshotter::Attributions attributions, mbgl::MapSnapshotter::PointForFn pointForFn, mbgl::MapSnapshotter::LatLngForFn latLngForFn, MHMapSnapshotOverlayHandler overlayHandler, NSError * _Nullable *outError);
NSArray<MHAttributionInfo *> *MHAttributionInfosFromAttributions(mbgl::MapSnapshotter::Attributions attributions);

class MHMapSnapshotterDelegateHost: public mbgl::MapSnapshotterObserver {
public:
    MHMapSnapshotterDelegateHost(MHMapSnapshotter *snapshotter_) : snapshotter(snapshotter_) {}
    
    void onDidFailLoadingStyle(const std::string& errorMessage) {
        MHMapSnapshotter *strongSnapshotter = snapshotter;
        if ([strongSnapshotter.delegate respondsToSelector:@selector(mapSnapshotterDidFail:withError:)]) {
            NSString *description = @(errorMessage.c_str());
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey: NSLocalizedStringWithDefaultValue(@"SNAPSHOT_LOAD_STYLE_FAILED_DESC", nil, nil, @"The snapshot failed because the style can’t be loaded.", @"User-friendly error description"),
                NSLocalizedFailureReasonErrorKey: description,
            };
            NSError *error = [NSError errorWithDomain:MHErrorDomain code:MHErrorCodeLoadStyleFailed userInfo:userInfo];
            [strongSnapshotter.delegate mapSnapshotterDidFail:snapshotter withError:error];
        }
    }
    
    void onDidFinishLoadingStyle() {
        MHMapSnapshotter *strongSnapshotter = snapshotter;
        if ([strongSnapshotter.delegate respondsToSelector:@selector(mapSnapshotter:didFinishLoadingStyle:)]) {
            [strongSnapshotter.delegate mapSnapshotter:snapshotter didFinishLoadingStyle:snapshotter.style];
        }
    }
    
    void onStyleImageMissing(const std::string& imageName) {
        MHMapSnapshotter *strongSnapshotter = snapshotter;
        if ([strongSnapshotter.delegate respondsToSelector:@selector(mapSnapshotter:didFailLoadingImageNamed:)]) {
            [strongSnapshotter.delegate mapSnapshotter:snapshotter didFailLoadingImageNamed:@(imageName.c_str())];
        }
    }
    
private:
    __weak MHMapSnapshotter *snapshotter;
};

@interface MHMapSnapshotOverlay() <MHMapSnapshotProtocol>
@property (nonatomic, assign) CGFloat scale;
- (instancetype)initWithContext:(CGContextRef)context scale:(CGFloat)scale pointForFn:(mbgl::MapSnapshotter::PointForFn)pointForFn latLngForFn:(mbgl::MapSnapshotter::LatLngForFn)latLngForFn;

@end

@implementation MHMapSnapshotOverlay {
    mbgl::MapSnapshotter::PointForFn _pointForFn;
    mbgl::MapSnapshotter::LatLngForFn _latLngForFn;
}

- (instancetype) initWithContext:(CGContextRef)context scale:(CGFloat)scale pointForFn:(mbgl::MapSnapshotter::PointForFn)pointForFn latLngForFn:(mbgl::MapSnapshotter::LatLngForFn)latLngForFn {
    self = [super init];
    if (self) {
        _context = context;
        _scale = scale;
        _pointForFn = pointForFn;
        _latLngForFn = latLngForFn;
    }

    return self;
}

#if TARGET_OS_IPHONE

- (CGPoint)pointForCoordinate:(CLLocationCoordinate2D)coordinate
{
    mbgl::ScreenCoordinate sc = _pointForFn(MHLatLngFromLocationCoordinate2D(coordinate));
    return CGPointMake(sc.x, sc.y);
}

- (CLLocationCoordinate2D)coordinateForPoint:(CGPoint)point
{
    mbgl::LatLng latLng = _latLngForFn(mbgl::ScreenCoordinate(point.x, point.y));
    return MHLocationCoordinate2DFromLatLng(latLng);
}

#else

- (NSPoint)pointForCoordinate:(CLLocationCoordinate2D)coordinate
{
    mbgl::ScreenCoordinate sc = _pointForFn(MHLatLngFromLocationCoordinate2D(coordinate));
    CGFloat height = ((CGFloat)CGBitmapContextGetHeight(self.context))/self.scale;
    return NSMakePoint(sc.x, height - sc.y);
}

- (CLLocationCoordinate2D)coordinateForPoint:(NSPoint)point
{
    CGFloat height = ((CGFloat)CGBitmapContextGetHeight(self.context))/self.scale;
    auto screenCoord = mbgl::ScreenCoordinate(point.x, height - point.y);
    mbgl::LatLng latLng = _latLngForFn(screenCoord);
    return MHLocationCoordinate2DFromLatLng(latLng);
}

#endif
@end

@implementation MHMapSnapshotOptions

- (instancetype _Nonnull)initWithStyleURL:(nullable NSURL *)styleURL camera:(MHMapCamera *)camera size:(CGSize)size
{
    MHLogDebug(@"Initializing withStyleURL: %@ camera: %@ size: %@", styleURL, camera, MHStringFromSize(size));
    self = [super init];
    if (self)
    {
        if ( !styleURL)
        {
            styleURL = [MHStyle defaultStyleURL];
        }
        _styleURL = styleURL;
        _size = size;
        _camera = camera;
        _showsLogo = YES;
#if TARGET_OS_IPHONE
        _scale = [UIScreen mainScreen].scale;
#else
        _scale = [NSScreen mainScreen].backingScaleFactor;
#endif
    }
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    __typeof__(self) copy = [[[self class] alloc] initWithStyleURL:_styleURL camera:_camera size:_size];
    copy.zoomLevel = _zoomLevel;
    copy.coordinateBounds = _coordinateBounds;
    copy.scale = _scale;
    copy.showsLogo = _showsLogo;
    return copy;
}

@end

@interface MHMapSnapshot() <MHMapSnapshotProtocol>
- (instancetype)initWithImage:(nullable MHImage *)image scale:(CGFloat)scale pointForFn:(mbgl::MapSnapshotter::PointForFn)pointForFn latLngForFn:(mbgl::MapSnapshotter::LatLngForFn)latLngForFn;

@property (nonatomic) CGFloat scale;
@end

@implementation MHMapSnapshot {
    mbgl::MapSnapshotter::PointForFn _pointForFn;
    mbgl::MapSnapshotter::LatLngForFn _latLngForFn;
}

- (instancetype)initWithImage:(nullable MHImage *)image scale:(CGFloat)scale pointForFn:(mbgl::MapSnapshotter::PointForFn)pointForFn latLngForFn:(mbgl::MapSnapshotter::LatLngForFn)latLngForFn
{
    self = [super init];
    if (self) {
        _pointForFn = pointForFn;
        _latLngForFn = latLngForFn;
        _scale = scale;
        _image = image;
    }
    return self;
}

#if TARGET_OS_IPHONE

- (CGPoint)pointForCoordinate:(CLLocationCoordinate2D)coordinate
{
    mbgl::ScreenCoordinate sc = _pointForFn(MHLatLngFromLocationCoordinate2D(coordinate));
    return CGPointMake(sc.x, sc.y);
}

- (CLLocationCoordinate2D)coordinateForPoint:(CGPoint)point
{
    mbgl::LatLng latLng = _latLngForFn(mbgl::ScreenCoordinate(point.x, point.y));
    return MHLocationCoordinate2DFromLatLng(latLng);
}

#else

- (NSPoint)pointForCoordinate:(CLLocationCoordinate2D)coordinate
{
    mbgl::ScreenCoordinate sc = _pointForFn(MHLatLngFromLocationCoordinate2D(coordinate));
    return NSMakePoint(sc.x, self.image.size.height - sc.y);
}

- (CLLocationCoordinate2D)coordinateForPoint:(NSPoint)point
{
    auto screenCoord = mbgl::ScreenCoordinate(point.x, self.image.size.height - point.y);
    mbgl::LatLng latLng = _latLngForFn(screenCoord);
    return MHLocationCoordinate2DFromLatLng(latLng);
}

#endif

@end

@interface MHMapSnapshotter()
@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL terminated;
@end

@implementation MHMapSnapshotter {
    std::unique_ptr<mbgl::MapSnapshotter> _mbglMapSnapshotter;
    std::unique_ptr<MHMapSnapshotterDelegateHost> _delegateHost;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancel];
}

- (instancetype)init {
    NSAssert(NO, @"Please use -[MHMapSnapshotter initWithOptions:]");
    [super doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithOptions:(MHMapSnapshotOptions *)options
{
    MHLogDebug(@"Initializing withOptions: %@", options);
    self = [super init];
    if (self) {
        self.options = options;
#if TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
#else
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
#endif
    }
    return self;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self cancel];
    self.terminated = YES;
}

- (void)startWithCompletionHandler:(MHMapSnapshotCompletionHandler)completion
{
    MHLogDebug(@"Starting withCompletionHandler: %@", completion);
    [self startWithQueue:dispatch_get_main_queue() completionHandler:completion];
}

- (void)startWithQueue:(dispatch_queue_t)queue completionHandler:(MHMapSnapshotCompletionHandler)completionHandler {
    [self startWithQueue:queue overlayHandler:nil completionHandler:completionHandler];
}

- (void)startWithOverlayHandler:(MHMapSnapshotOverlayHandler)overlayHandler completionHandler:(MHMapSnapshotCompletionHandler)completion {
    [self startWithQueue:dispatch_get_main_queue() overlayHandler:overlayHandler completionHandler:completion];
}

- (void)startWithQueue:(dispatch_queue_t)queue overlayHandler:(MHMapSnapshotOverlayHandler)overlayHandler completionHandler:(MHMapSnapshotCompletionHandler)completion
{
    if (!completion) {
        return;
    }
    
    // Ensure that offline storage has been initialized on the main thread, as MHMapView and MHOfflineStorage do when used directly.
    // https://github.com/mapbox/mapbox-gl-native-ios/issues/227
    if ([NSThread.currentThread isMainThread]) {
        (void)[MHOfflineStorage sharedOfflineStorage];
    } else {
        [NSException raise:NSInvalidArgumentException
                    format:@"-[MHMapSnapshotter startWithQueue:completionHandler:] must be called from the main thread, not %@.", NSThread.currentThread];
    }

    if (self.loading) {
        // Consider replacing this exception with an error passed to the completion block.
        [NSException raise:NSInternalInconsistencyException
                    format:@"Already started this snapshotter."];
    }
    self.loading = YES;

    if (self.terminated) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Starting a snapshotter after application termination is not supported."];
    }
    
    MHMapSnapshotOptions *options = [self.options copy];
    [self configureWithOptions:options];
    MHLogDebug(@"Starting with options: %@", self.options);

    // Temporarily capture the snapshotter until the completion handler finishes executing, to keep standalone local usage of the snapshotter from becoming a no-op.
    // POSTCONDITION: Only refer to this variable in the final result queue.
    // POSTCONDITION: It is important to nil out this variable at some point in the future to avoid a leak. In cases where the completion handler gets called, the variable should be nilled out explicitly. If -cancel is called, mbgl releases the snapshot block below, causing the only remaining references to the snapshotter to go out of scope.
    __block MHMapSnapshotter *strongSelf = self;
    _mbglMapSnapshotter->snapshot(^(std::exception_ptr mbglError, mbgl::PremultipliedImage image, mbgl::MapSnapshotter::Attributions attributions, mbgl::MapSnapshotter::PointForFn pointForFn, mbgl::MapSnapshotter::LatLngForFn latLngForFn) {
        if (mbglError) {
            NSString *description = @(mbgl::util::toString(mbglError).c_str());
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: description};
            NSError *error = [NSError errorWithDomain:MHErrorDomain code:MHErrorCodeSnapshotFailed userInfo:userInfo];

            // Dispatch to result queue
            dispatch_async(queue, ^{
                strongSelf.loading = NO;
                completion(nil, error);
                strongSelf = nil;
            });
        } else {
#if TARGET_OS_IPHONE
            MHImage *mglImage = [[MHImage alloc] initWithMHPremultipliedImage:std::move(image) scale:options.scale];
#else
            MHImage *mglImage = [[MHImage alloc] initWithMHPremultipliedImage:std::move(image)];
            mglImage.size = NSMakeSize(mglImage.size.width / options.scale,
                                       mglImage.size.height / options.scale);
#endif
            // Process image watermark in a work queue
            dispatch_queue_t workQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            
            dispatch_async(workQueue, ^{
                // Call a function that cannot accidentally capture self.
                NSError *error;
                MHMapSnapshot *snapshot = MHSnapshotWithDecoratedImage(mglImage, options, attributions, pointForFn, latLngForFn, overlayHandler, &error);
                
                // Dispatch result to result queue
                dispatch_async(queue, ^{
                    strongSelf.loading = NO;
                    completion(snapshot, error);
                    strongSelf = nil;
                });
            });
        }
    });
}

MHImage *MHAttributedSnapshot(mbgl::MapSnapshotter::Attributions attributions, MHImage *mglImage, MHMapSnapshotOptions *options, void (^overlayHandler)()) {

    NSArray<MHAttributionInfo *> *attributionInfo = MHAttributionInfosFromAttributions(attributions);

#if TARGET_OS_IPHONE
    MHAttributionInfoStyle attributionInfoStyle = MHAttributionInfoStyleLong;
    for (NSUInteger styleValue = MHAttributionInfoStyleLong; styleValue >= MHAttributionInfoStyleShort; styleValue--) {
        attributionInfoStyle = (MHAttributionInfoStyle)styleValue;
        CGSize attributionSize = [MHMapSnapshotter attributionSizeWithLogoStyle:attributionInfoStyle sourceAttributionStyle:attributionInfoStyle attributionInfo:attributionInfo];
        if (attributionSize.width <= mglImage.size.width) {
            break;
        }
    }

    UIImage *logoImage = [MHMapSnapshotter logoImageWithStyle:attributionInfoStyle];
    CGSize attributionBackgroundSize = [MHMapSnapshotter attributionTextSizeWithStyle:attributionInfoStyle attributionInfo:attributionInfo];
    
    CGRect logoImageRect = CGRectMake(MHLogoImagePosition.x, mglImage.size.height - (MHLogoImagePosition.y + logoImage.size.height), logoImage.size.width, logoImage.size.height);
    CGPoint attributionOrigin = CGPointMake(mglImage.size.width - 10 - attributionBackgroundSize.width,
                                            logoImageRect.origin.y + (logoImageRect.size.height / 2) - (attributionBackgroundSize.height / 2) + 1);
    if (!logoImage) {
        CGSize defaultLogoSize = [MHMapSnapshotter maplibreLongStyleLogo].size;
        logoImageRect = CGRectMake(0, mglImage.size.height - (MHLogoImagePosition.y + defaultLogoSize.height), 0, defaultLogoSize.height);
        attributionOrigin = CGPointMake(10, logoImageRect.origin.y + (logoImageRect.size.height / 2) - (attributionBackgroundSize.height / 2) + 1);
    }
    
    CGRect attributionBackgroundFrame = CGRectMake(attributionOrigin.x,
                                                   attributionOrigin.y,
                                                   attributionBackgroundSize.width,
                                                   attributionBackgroundSize.height);
    CGPoint attributionTextPosition = CGPointMake(attributionBackgroundFrame.origin.x + 10,
                                                  attributionBackgroundFrame.origin.y - 1);
    
    CGRect cropRect = CGRectMake(attributionBackgroundFrame.origin.x * mglImage.scale,
                                 attributionBackgroundFrame.origin.y * mglImage.scale,
                                 attributionBackgroundSize.width * mglImage.scale,
                                 attributionBackgroundSize.height * mglImage.scale);
    
    UIGraphicsBeginImageContextWithOptions(mglImage.size, NO, options.scale);
    
    [mglImage drawInRect:CGRectMake(0, 0, mglImage.size.width, mglImage.size.height)];

    overlayHandler();
    CGContextRef currentContext = UIGraphicsGetCurrentContext();

    if (!currentContext) {
        // If the current context has been corrupted by the user,
        // return nil so we can generate an error later.
        return nil;
    }

    if (options.showsLogo) {
        [logoImage drawInRect:logoImageRect];
    }
    
    UIImage *currentImage = UIGraphicsGetImageFromCurrentImageContext();
    CGImageRef attributionImageRef = CGImageCreateWithImageInRect([currentImage CGImage], cropRect);
    UIImage *attributionImage = [UIImage imageWithCGImage:attributionImageRef];
    CGImageRelease(attributionImageRef);
    
    CIImage *ciAttributionImage = [[CIImage alloc] initWithCGImage:attributionImage.CGImage];
    
    UIImage *blurredAttributionBackground = [MHMapSnapshotter blurredAttributionBackground:ciAttributionImage];
    
    [blurredAttributionBackground drawInRect:attributionBackgroundFrame];
    
    [MHMapSnapshotter drawAttributionTextWithStyle:attributionInfoStyle origin:attributionTextPosition attributionInfo:attributionInfo];
    
    UIImage *compositedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();

    return compositedImage;

#else
    NSRect targetFrame = { .origin = NSZeroPoint, .size = options.size };
    
    MHAttributionInfoStyle attributionInfoStyle = MHAttributionInfoStyleLong;
    for (NSUInteger styleValue = MHAttributionInfoStyleLong; styleValue >= MHAttributionInfoStyleShort; styleValue--) {
        attributionInfoStyle = (MHAttributionInfoStyle)styleValue;
        CGSize attributionSize = [MHMapSnapshotter attributionSizeWithLogoStyle:attributionInfoStyle sourceAttributionStyle:attributionInfoStyle attributionInfo:attributionInfo];
        if (attributionSize.width <= mglImage.size.width) {
            break;
        }
    }
    
    NSImage *logoImage = [MHMapSnapshotter logoImageWithStyle:attributionInfoStyle];
    CGSize attributionBackgroundSize = [MHMapSnapshotter attributionTextSizeWithStyle:attributionInfoStyle attributionInfo:attributionInfo];
    NSImage *sourceImage = mglImage;
    
    CGRect logoImageRect = CGRectMake(MHLogoImagePosition.x, MHLogoImagePosition.y, logoImage.size.width, logoImage.size.height);
    CGPoint attributionOrigin = CGPointMake(targetFrame.size.width - 10 - attributionBackgroundSize.width,
                                            MHLogoImagePosition.y + 1);
    if (!logoImage) {
        CGSize defaultLogoSize = [MHMapSnapshotter maplibreLongStyleLogo].size;
        logoImageRect = CGRectMake(0, MHLogoImagePosition.y, 0, defaultLogoSize.height);
        attributionOrigin = CGPointMake(10, attributionOrigin.y);
    }
    
    CGRect attributionBackgroundFrame = CGRectMake(attributionOrigin.x,
                                                   attributionOrigin.y,
                                                   attributionBackgroundSize.width,
                                                   attributionBackgroundSize.height);
    CGPoint attributionTextPosition = CGPointMake(attributionBackgroundFrame.origin.x + 10,
                                                  logoImageRect.origin.y + (logoImageRect.size.height / 2) - (attributionBackgroundSize.height / 2));
    
    
    NSImage *compositedImage = nil;
    NSImageRep *sourceImageRep = [sourceImage bestRepresentationForRect:targetFrame
                                                                context:nil
                                                                  hints:nil];
    compositedImage = [[NSImage alloc] initWithSize:targetFrame.size];
    
    [compositedImage lockFocus];
    
    [sourceImageRep drawInRect: targetFrame];
    
    overlayHandler();
    
    NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
    if (!currentContext) {
        // If the current context has been corrupted by the user,
        // return nil so we can generate an error later.
        return nil;
    }
    
    if (logoImage) {
        [logoImage drawInRect:logoImageRect];
    }
    
    NSBitmapImageRep *attributionBackground = [[NSBitmapImageRep alloc] initWithFocusedViewRect:attributionBackgroundFrame];
    
    CIImage *attributionBackgroundImage = [[CIImage alloc] initWithCGImage:[attributionBackground CGImage]];
    
    NSImage *blurredAttributionBackground = [MHMapSnapshotter blurredAttributionBackground:attributionBackgroundImage];
    
    [blurredAttributionBackground drawInRect:attributionBackgroundFrame];
    
    [MHMapSnapshotter drawAttributionTextWithStyle:attributionInfoStyle origin:attributionTextPosition attributionInfo:attributionInfo];
    
    [compositedImage unlockFocus];

    return compositedImage;
#endif
}

MHMapSnapshot *MHSnapshotWithDecoratedImage(MHImage *mglImage, MHMapSnapshotOptions *options, mbgl::MapSnapshotter::Attributions attributions, mbgl::MapSnapshotter::PointForFn pointForFn, mbgl::MapSnapshotter::LatLngForFn latLngForFn, MHMapSnapshotOverlayHandler overlayHandler, NSError * _Nullable *outError) {
    MHImage *compositedImage = MHAttributedSnapshot(attributions, mglImage, options, ^{
        if (!overlayHandler) {
            return;
        }
#if TARGET_OS_IPHONE
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (!context) {
            return;
        }
        MHMapSnapshotOverlay *snapshotOverlay = [[MHMapSnapshotOverlay alloc] initWithContext:context
                                                                                          scale:options.scale
                                                                                     pointForFn:pointForFn
                                                                                    latLngForFn:latLngForFn];
        CGContextSaveGState(context);
        overlayHandler(snapshotOverlay);
        CGContextRestoreGState(context);
#else
        NSGraphicsContext *context = [NSGraphicsContext currentContext];
        if (!context) {
            return;
        }
        MHMapSnapshotOverlay *snapshotOverlay = [[MHMapSnapshotOverlay alloc] initWithContext:context.CGContext
                                                                                          scale:options.scale
                                                                                     pointForFn:pointForFn
                                                                                    latLngForFn:latLngForFn];
        [context saveGraphicsState];
        overlayHandler(snapshotOverlay);
        [context restoreGraphicsState];
#endif
    });
    
    if (compositedImage) {
        return [[MHMapSnapshot alloc] initWithImage:compositedImage
                                               scale:options.scale
                                          pointForFn:pointForFn
                                         latLngForFn:latLngForFn];
    } else {
        if (outError) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Failed to generate composited snapshot."};
            *outError = [NSError errorWithDomain:MHErrorDomain
                                        code:MHErrorCodeSnapshotFailed
                                    userInfo:userInfo];
        }
        return nil;
    }
}

NSArray<MHAttributionInfo *> *MHAttributionInfosFromAttributions(mbgl::MapSnapshotter::Attributions attributions) {
    NSMutableArray *infos = [NSMutableArray array];
    
#if TARGET_OS_IPHONE
    CGFloat fontSize = [UIFont smallSystemFontSize];
    UIColor *attributeFontColor = [UIColor blackColor];
#else
    CGFloat fontSize = [NSFont systemFontSizeForControlSize:NSControlSizeMini];
    NSColor *attributeFontColor = [NSColor blackColor];
#endif
    for (auto attribution : attributions) {
        NSString *attributionHTMLString = @(attribution.c_str());
        NSArray *tileSetInfos = [MHAttributionInfo attributionInfosFromHTMLString:attributionHTMLString
                                                                          fontSize:fontSize
                                                                         linkColor:attributeFontColor];
        [infos growArrayByAddingAttributionInfosFromArray:tileSetInfos];
    }
    return infos;
}

+ (void)drawAttributionTextWithStyle:(MHAttributionInfoStyle)attributionInfoStyle origin:(CGPoint)origin attributionInfo:(NSArray<MHAttributionInfo *>*)attributionInfo
{
    for (MHAttributionInfo *info in attributionInfo) {
        if (info.isFeedbackLink) {
            continue;
        }
        NSAttributedString *attribution = [info titleWithStyle:attributionInfoStyle];
        [attribution drawAtPoint:origin];
        
        origin.x += [attribution size].width + 10;
    }
}

+ (MHImage *)blurredAttributionBackground:(CIImage *)backgroundImage
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    CIFilter *clamp = [CIFilter filterWithName:@"CIAffineClamp"];
    [clamp setValue:backgroundImage forKey:kCIInputImageKey];
    [clamp setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    
    CIFilter *attributionBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [attributionBlurFilter setValue:[clamp outputImage] forKey:kCIInputImageKey];
    [attributionBlurFilter setValue:@10 forKey:kCIInputRadiusKey];
    
    CIFilter *attributionColorFilter = [CIFilter filterWithName:@"CIColorControls"];
    [attributionColorFilter setValue:[attributionBlurFilter outputImage] forKey:kCIInputImageKey];
    [attributionColorFilter setValue:@(0.1) forKey:kCIInputBrightnessKey];
    
    CIImage *blurredImage = attributionColorFilter.outputImage;
    
    CIContext *ctx = [CIContext contextWithOptions:nil];
    CGImageRef cgimg = [ctx createCGImage:blurredImage fromRect:[backgroundImage extent]];
    MHImage *image;
    
#if TARGET_OS_IPHONE
    image = [UIImage imageWithCGImage:cgimg];
#else
    image = [[NSImage alloc] initWithCGImage:cgimg size:[backgroundImage extent].size];
#endif

    CGImageRelease(cgimg);
    return image;
}

+ (MHImage *)logoImageWithStyle:(MHAttributionInfoStyle)style
{
    MHImage *logoImage;
    switch (style) {
        case MHAttributionInfoStyleLong:
            logoImage = [MHMapSnapshotter maplibreLongStyleLogo];
            break;
        case MHAttributionInfoStyleMedium:
#if TARGET_OS_IPHONE
            logoImage = [UIImage imageNamed:@"maplibre-logo-icon" inBundle:[NSBundle mgl_frameworkBundle] compatibleWithTraitCollection:nil];
#else
            logoImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mgl_frameworkBundle] pathForResource:@"mapbox_helmet" ofType:@"pdf"]];
#endif
            break;
        case MHAttributionInfoStyleShort:
            logoImage = nil;
            break;
    }
    return logoImage;
}

+ (MHImage *)maplibreLongStyleLogo
{
    MHImage *logoImage;
#if TARGET_OS_IPHONE
    logoImage =[UIImage imageNamed:@"maplibre-logo-stroke-gray" inBundle:[NSBundle mgl_frameworkBundle] compatibleWithTraitCollection:nil];
#else
    logoImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mgl_frameworkBundle] pathForResource:@"mapbox" ofType:@"pdf"]];
#endif
    return logoImage;
}

+ (CGSize)attributionSizeWithLogoStyle:(MHAttributionInfoStyle)logoStyle sourceAttributionStyle:(MHAttributionInfoStyle)attributionStyle attributionInfo:(NSArray<MHAttributionInfo *>*)attributionInfo
{
    MHImage *logoImage = [self logoImageWithStyle:logoStyle];
    
    CGSize attributionBackgroundSize = [MHMapSnapshotter attributionTextSizeWithStyle:attributionStyle attributionInfo:attributionInfo];
    
    CGSize attributionSize = CGSizeZero;
    
    if (logoImage) {
        attributionSize.width = MHLogoImagePosition.x + logoImage.size.width + 10;
    }
    attributionSize.width = attributionSize.width + 10 + attributionBackgroundSize.width + 10;
    attributionSize.height = MAX(logoImage.size.height, attributionBackgroundSize.height);
    
    return attributionSize;
}

+ (CGSize)attributionTextSizeWithStyle:(MHAttributionInfoStyle)attributionStyle attributionInfo:(NSArray<MHAttributionInfo *>*)attributionInfo
{
    CGSize attributionBackgroundSize = CGSizeMake(10, 0);
    for (MHAttributionInfo *info in attributionInfo) {
        if (info.isFeedbackLink) {
            continue;
        }
        CGSize attributionSize = [info titleWithStyle:attributionStyle].size;
        attributionBackgroundSize.width += attributionSize.width + 10;
        attributionBackgroundSize.height = MAX(attributionSize.height, attributionBackgroundSize.height);
    }
    
    return attributionBackgroundSize;
}

- (void)cancel
{
    MHLogInfo(@"Cancelling snapshotter.");
    
    if (_mbglMapSnapshotter) {
        _mbglMapSnapshotter->cancel();
    }
    _mbglMapSnapshotter.reset();
    _delegateHost.reset();
}

- (void)configureWithOptions:(MHMapSnapshotOptions *)options {
    auto mbglFileSource = [[MHOfflineStorage sharedOfflineStorage] mbglFileSource];
    
    // Size; taking into account the minimum texture size for OpenGL ES
    // For non retina screens the ratio is 1:1 MHSnapshotterMinimumPixelSize
    mbgl::Size size = {
        static_cast<uint32_t>(MAX(options.size.width, MHSnapshotterMinimumPixelSize)),
        static_cast<uint32_t>(MAX(options.size.height, MHSnapshotterMinimumPixelSize))
    };
    
    float pixelRatio = MAX(options.scale, 1);
    
    // App-global configuration
    MHRendererConfiguration *config = [MHRendererConfiguration currentConfiguration];

    auto tileServerOptions = [[MHSettings sharedSettings] tileServerOptionsInternal];
    mbgl::ResourceOptions resourceOptions;
    resourceOptions
        .withTileServerOptions(*tileServerOptions)
        .withCachePath(MHOfflineStorage.sharedOfflineStorage.databasePath.UTF8String)
        .withAssetPath(NSBundle.mainBundle.resourceURL.path.UTF8String);
    mbgl::ClientOptions clientOptions;

    auto apiKey = [[MHSettings sharedSettings] apiKey];
    if (apiKey) {
        resourceOptions.withApiKey([apiKey UTF8String]);
    }                   

    // Create the snapshotter
    auto localFontFamilyName = config.localFontFamilyName ? std::string(config.localFontFamilyName.UTF8String) : nullptr;
    _delegateHost = std::make_unique<MHMapSnapshotterDelegateHost>(self);
    _mbglMapSnapshotter = std::make_unique<mbgl::MapSnapshotter>(
                                                                 size, pixelRatio, resourceOptions, clientOptions, *_delegateHost, localFontFamilyName);
    
    _mbglMapSnapshotter->setStyleURL(std::string(options.styleURL.absoluteString.UTF8String));
    
    // Camera options
    mbgl::CameraOptions cameraOptions;
    if (CLLocationCoordinate2DIsValid(options.camera.centerCoordinate)) {
        cameraOptions.center = MHLatLngFromLocationCoordinate2D(options.camera.centerCoordinate);
    }
    if (options.camera.heading >= 0) {
        cameraOptions.bearing = MAX(0, options.camera.heading);
    }
    if (options.zoomLevel >= 0) {
        cameraOptions.zoom = MAX(0, options.zoomLevel);
    }
    if (options.camera.pitch >= 0) {
        cameraOptions.pitch = MAX(0, options.camera.pitch);
    }
    if (cameraOptions != mbgl::CameraOptions()) {
        _mbglMapSnapshotter->setCameraOptions(cameraOptions);
    }
    
    // Region
    if (!MHCoordinateBoundsIsEmpty(options.coordinateBounds)) {
        _mbglMapSnapshotter->setRegion(MHLatLngBoundsFromCoordinateBounds(options.coordinateBounds));
    }
}

- (MHStyle *)style {
    if (!_mbglMapSnapshotter) {
        return nil;
    }
    return [[MHStyle alloc] initWithRawStyle:&_mbglMapSnapshotter->getStyle() stylable:self];
}

@end
