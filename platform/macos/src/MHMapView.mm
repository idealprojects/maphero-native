#import "MHMapView_Private.h"

#import "MHAttributionButton.h"
#import "MHCompassCell.h"
#import "MHStyle.h"
#import "MHRendererFrontend.h"
#import "MHRendererConfiguration.h"

#import "MHAnnotationImage_Private.h"
#import "MHAttributionInfo_Private.h"
#import "MHFeature_Private.h"
#import "MHFoundation_Private.h"
#import "MHGeometry_Private.h"
#import "MHMultiPoint_Private.h"
#import "MHOfflineStorage_Private.h"
#import "MHStyle_Private.h"
#import "MHShape_Private.h"

#import "MHSettings.h"
#import "MHMapCamera.h"
#import "MHPolygon.h"
#import "MHPolyline.h"
#import "MHAnnotationImage.h"
#import "MHMapViewDelegate.h"
#import "MHImageSource.h"

#import <mbgl/map/map.hpp>
#import <mbgl/map/map_options.hpp>
#import <mbgl/style/style.hpp>
#import <mbgl/annotation/annotation.hpp>
#import <mbgl/map/camera.hpp>
#import <mbgl/style/image.hpp>
#import <mbgl/renderer/renderer.hpp>
#import <mbgl/storage/network_status.hpp>
#import <mbgl/storage/resource_options.hpp>
#import <mbgl/math/wrap.hpp>
#import <mbgl/util/client_options.hpp>
#import <mbgl/util/constants.hpp>
#import <mbgl/util/chrono.hpp>
#import <mbgl/util/exception.hpp>
#import <mbgl/util/run_loop.hpp>
#import <mbgl/util/string.hpp>
#import <mbgl/util/projection.hpp>

#import <map>
#import <unordered_map>
#import <unordered_set>

#import "MHMapView+Impl.h"
#import "NSBundle+MHAdditions.h"
#import "NSDate+MHAdditions.h"
#import "NSProcessInfo+MHAdditions.h"
#import "NSException+MHAdditions.h"
#import "NSString+MHAdditions.h"
#import "NSURL+MHAdditions.h"
#import "NSColor+MHAdditions.h"
#import "NSImage+MHAdditions.h"
#import "NSPredicate+MHPrivateAdditions.h"
#import "MHNetworkConfiguration_Private.h"
#import "MHLoggingConfiguration_Private.h"
#import "MHReachability.h"
#import "MHSettings_Private.h"

#import <CoreImage/CIFilter.h>

class MHAnnotationContext;

/// Distance from the edge of the view to ornament views (logo, attribution, etc.).
const CGFloat MHOrnamentPadding = 12;

/// Alpha value of the ornament views (logo, attribution, etc.).
const CGFloat MHOrnamentOpacity = 0.9;

/// Default duration for programmatic animations.
const NSTimeInterval MHAnimationDuration = 0.3;

/// Distance in points that a single press of the panning keyboard shortcut pans the map by.
const CGFloat MHKeyPanningIncrement = 150;

/// Degrees that a single press of the rotation keyboard shortcut rotates the map by.
const CLLocationDegrees MHKeyRotationIncrement = 25;

/// Key for the user default that, when true, causes the map view to zoom in and out on scroll wheel events.
NSString * const MHScrollWheelZoomsMapViewDefaultKey = @"MHScrollWheelZoomsMapView";

/// Reuse identifier and file name of the default point annotation image.
static NSString * const MHDefaultStyleMarkerSymbolName = @"default_marker";

/// Prefix that denotes a sprite installed by MHMapView, to avoid collisions
/// with style-defined sprites.
static NSString * const MHAnnotationSpritePrefix = @"org.maplibre.sprites.";

/// Slop area around the hit testing point, allowing for imprecise annotation selection.
const CGFloat MHAnnotationImagePaddingForHitTest = 4;

/// Distance from the callout’s anchor point to the annotation it points to.
const CGFloat MHAnnotationImagePaddingForCallout = 4;

/// Padding to edge of view that an offscreen annotation must have when being brought onscreen (by being selected)
const NSEdgeInsets MHMapViewOffscreenAnnotationPadding = NSEdgeInsetsMake(-30.0f, -30.0f, -30.0f, -30.0f);

/// Unique identifier representing a single annotation in mbgl.
typedef uint64_t MHAnnotationTag;

/// An indication that the requested annotation was not found or is nonexistent.
enum { MHAnnotationTagNotFound = UINT64_MAX };

/// Mapping from an annotation tag to metadata about that annotation, including
/// the annotation itself.
typedef std::unordered_map<MHAnnotationTag, MHAnnotationContext> MHAnnotationTagContextMap;

/// Mapping from an annotation object to an annotation tag.
typedef std::map<id<MHAnnotation>, MHAnnotationTag> MHAnnotationObjectTagMap;

/// Returns an NSImage for the default marker image.
NSImage *MHDefaultMarkerImage() {
    NSString *path = [[NSBundle mgl_frameworkBundle] pathForResource:MHDefaultStyleMarkerSymbolName
                                                              ofType:@"pdf"];
    return [[NSImage alloc] initWithContentsOfFile:path];
}

/// Converts a media timing function into a unit bezier object usable in mbgl.
mbgl::util::UnitBezier MHUnitBezierForMediaTimingFunction(CAMediaTimingFunction *function) {
    if (!function) {
        function = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    }
    float p1[2], p2[2];
    [function getControlPointAtIndex:0 values:p1];
    [function getControlPointAtIndex:1 values:p2];
    return { p1[0], p1[1], p2[0], p2[1] };
}

/// Lightweight container for metadata about an annotation, including the annotation itself.
class MHAnnotationContext {
public:
    id <MHAnnotation> annotation;
    /// The annotation’s image’s reuse identifier.
    NSString *imageReuseIdentifier;
};

@interface MHMapView () <NSPopoverDelegate, MHMultiPointDelegate, NSGestureRecognizerDelegate>

@property (nonatomic, readwrite) NSSegmentedControl *zoomControls;
@property (nonatomic, readwrite) NSSlider *compass;
@property (nonatomic, readwrite) NSImageView *logoView;
@property (nonatomic, readwrite) NSView *attributionView;

@property (nonatomic, readwrite) MHStyle *style;

/// Mapping from reusable identifiers to annotation images.
@property (nonatomic) NSMutableDictionary<NSString *, MHAnnotationImage *> *annotationImagesByIdentifier;
/// Currently shown popover representing the selected annotation.
@property (nonatomic) NSPopover *calloutForSelectedAnnotation;

@property (nonatomic, readwrite, getter=isDormant) BOOL dormant;

@end

@implementation MHMapView {
    /// Cross-platform map view controller.
    std::unique_ptr<mbgl::Map> _mbglMap;
    std::unique_ptr<MHMapViewImpl> _mbglView;
    std::unique_ptr<MHRenderFrontend> _rendererFrontend;

    NSPanGestureRecognizer *_panGestureRecognizer;
    NSMagnificationGestureRecognizer *_magnificationGestureRecognizer;
    NSRotationGestureRecognizer *_rotationGestureRecognizer;
    NSClickGestureRecognizer *_singleClickRecognizer;
    double _zoomAtBeginningOfGesture;
    CLLocationDirection _directionAtBeginningOfGesture;
    CGFloat _pitchAtBeginningOfGesture;
    BOOL _didHideCursorDuringGesture;

    MHAnnotationTagContextMap _annotationContextsByAnnotationTag;
    MHAnnotationObjectTagMap _annotationTagsByAnnotation;
    MHAnnotationTag _selectedAnnotationTag;
    MHAnnotationTag _lastSelectedAnnotationTag;
    /// Size of the rectangle formed by unioning the maximum slop area around every annotation image.
    NSSize _unionedAnnotationImageSize;
    std::vector<MHAnnotationTag> _annotationsNearbyLastClick;
    /// True if any annotations that have tooltips have been installed.
    BOOL _wantsToolTipRects;
    /// True if any annotation images that have custom cursors have been installed.
    BOOL _wantsCursorRects;
    /// True if a willChange notification has been issued for shape annotation layers and a didChange notification is pending.
    BOOL _isChangingAnnotationLayers;

    // Cached checks for delegate method implementations that may be called from
    // MHMultiPointDelegate methods.

    BOOL _delegateHasAlphasForShapeAnnotations;
    BOOL _delegateHasStrokeColorsForShapeAnnotations;
    BOOL _delegateHasFillColorsForShapeAnnotations;
    BOOL _delegateHasLineWidthsForShapeAnnotations;

    /// True if the current process is the Interface Builder designable
    /// renderer. When drawing the designable, the map is paused, so any call to
    /// it may hang the process.
    BOOL _isTargetingInterfaceBuilder;
    CLLocationDegrees _pendingLatitude;
    CLLocationDegrees _pendingLongitude;

    /// True if the view is currently printing itself.
    BOOL _isPrinting;

    /// reachability instance
    MHReachability *_reachability;
}

// MARK: Lifecycle

+ (void)initialize {
    if (self == [MHMapView class]) {
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{
            MHScrollWheelZoomsMapViewDefaultKey: @NO,
        }];
    }
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        MHLogInfo(@"Starting %@ initialization.", NSStringFromClass([self class]));
        MHLogDebug(@"Initializing frame: %@", NSStringFromRect(frameRect));
        [self commonInit];
        self.styleURL = nil;
        MHLogInfo(@"Finalizing %@ initialization.", NSStringFromClass([self class]));
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frame styleURL:(nullable NSURL *)styleURL {
    if (self = [super initWithFrame:frame]) {
        MHLogInfo(@"Starting %@ initialization.", NSStringFromClass([self class]));
        MHLogDebug(@"Initializing frame: %@ styleURL: %@", NSStringFromRect(frame), styleURL);
        [self commonInit];
        self.styleURL = styleURL;
        MHLogInfo(@"Finalizing %@ initialization.", NSStringFromClass([self class]));
    }
    return self;
}

- (instancetype)initWithCoder:(nonnull NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        MHLogInfo(@"Starting %@ initialization.", NSStringFromClass([self class]));
        [self commonInit];
        MHLogInfo(@"Finalizing %@ initialization.", NSStringFromClass([self class]));
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    // If the Style URL inspectable was not set, make sure to go through
    // -setStyleURL: to load the default style.
    if (_mbglMap->getStyle().getURL().empty()) {
        self.styleURL = nil;
    }
}

+ (NSArray *)restorableStateKeyPaths {
    return @[@"camera", @"debugMask"];
}

- (void)commonInit {
    [MHNetworkConfiguration sharedManager];

    _isTargetingInterfaceBuilder = NSProcessInfo.processInfo.mgl_isInterfaceBuilderDesignablesAgent;

    // Set up cross-platform controllers and resources.
    _mbglView = MHMapViewImpl::Create(self);

    // Delete the pre-offline ambient cache at
    // ~/Library/Caches/com.mapbox.MapboxGL/cache.db.
    NSURL *cachesDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
                                                                       inDomain:NSUserDomainMask
                                                              appropriateForURL:nil
                                                                         create:NO
                                                                          error:nil];
    cachesDirectoryURL = [cachesDirectoryURL URLByAppendingPathComponent:@"com.mapbox.MapboxGL"];
    NSURL *legacyCacheURL = [cachesDirectoryURL URLByAppendingPathComponent:@"cache.db"];
    [[NSFileManager defaultManager] removeItemAtURL:legacyCacheURL error:NULL];

    MHRendererConfiguration *config = [MHRendererConfiguration currentConfiguration];

    auto localFontFamilyName = config.localFontFamilyName ? std::string(config.localFontFamilyName.UTF8String) : nullptr;
    auto renderer = std::make_unique<mbgl::Renderer>(_mbglView->getRendererBackend(), config.scaleFactor, localFontFamilyName);
    BOOL enableCrossSourceCollisions = !config.perSourceCollisions;
    _rendererFrontend = std::make_unique<MHRenderFrontend>(std::move(renderer), self, _mbglView->getRendererBackend(), true);

    mbgl::MapOptions mapOptions;
    mapOptions.withMapMode(mbgl::MapMode::Continuous)
              .withSize(self.size)
              .withPixelRatio(config.scaleFactor)
              .withConstrainMode(mbgl::ConstrainMode::None)
              .withViewportMode(mbgl::ViewportMode::Default)
              .withCrossSourceCollisions(enableCrossSourceCollisions);

    auto tileServerOptions = [[MHSettings sharedSettings] tileServerOptionsInternal];
    mbgl::ResourceOptions resourceOptions;
    resourceOptions.withTileServerOptions(*tileServerOptions)
                   .withCachePath(MHOfflineStorage.sharedOfflineStorage.databasePath.UTF8String)
                   .withAssetPath([NSBundle mainBundle].resourceURL.path.UTF8String);
    mbgl::ClientOptions clientOptions;

    auto apiKey = [[MHSettings sharedSettings] apiKey];
    if (apiKey) {
        resourceOptions.withApiKey([apiKey UTF8String]);
    }                     

    _mbglMap = std::make_unique<mbgl::Map>(*_rendererFrontend, *_mbglView, mapOptions, resourceOptions, clientOptions);

    // Notify map object when network reachability status changes.
    _reachability = [MHReachability reachabilityForInternetConnection];
    _reachability.reachableBlock = ^(MHReachability *) {
        mbgl::NetworkStatus::Reachable();
    };
    [_reachability startNotifier];

    // Install ornaments and gesture recognizers.
    [self installZoomControls];
    [self installCompass];
    [self installLogoView];
    [self installAttributionView];
    [self installGestureRecognizers];

    // Set up annotation management and selection state.
    _annotationImagesByIdentifier = [NSMutableDictionary dictionary];
    _annotationContextsByAnnotationTag = {};
    _annotationTagsByAnnotation = {};
    _selectedAnnotationTag = MHAnnotationTagNotFound;
    _lastSelectedAnnotationTag = MHAnnotationTagNotFound;
    _annotationsNearbyLastClick = {};

    // Jump to Null Island initially.
    self.automaticallyAdjustsContentInsets = YES;
    mbgl::CameraOptions options;
    options.center = mbgl::LatLng(0, 0);
    options.padding = MHEdgeInsetsFromNSEdgeInsets(self.contentInsets);
    options.zoom = *_mbglMap->getBounds().minZoom;
    _mbglMap->jumpTo(options);
    _pendingLatitude = NAN;
    _pendingLongitude = NAN;
}

- (mbgl::Size)size {
    // check for minimum texture size supported by OpenGL ES 2.0
    //
    CGSize size = CGSizeMake(MAX(self.bounds.size.width, 64), MAX(self.bounds.size.height, 64));
    return { static_cast<uint32_t>(size.width),
             static_cast<uint32_t>(size.height) };
}

- (mbgl::Size)framebufferSize {
    NSRect bounds = [self convertRectToBacking:self.bounds];
    return { static_cast<uint32_t>(bounds.size.width), static_cast<uint32_t>(bounds.size.height) };
}

/// Adds zoom controls to the lower-right corner.
- (void)installZoomControls {
    _zoomControls = [[NSSegmentedControl alloc] initWithFrame:NSZeroRect];
    _zoomControls.wantsLayer = YES;
    _zoomControls.layer.opacity = MHOrnamentOpacity;
    [(NSSegmentedCell *)_zoomControls.cell setTrackingMode:NSSegmentSwitchTrackingMomentary];
    _zoomControls.continuous = YES;
    _zoomControls.segmentCount = 2;
    [_zoomControls setLabel:NSLocalizedStringWithDefaultValue(@"ZOOM_OUT_LABEL", nil, nil, @"−", @"Label of Zoom Out button; U+2212 MINUS SIGN") forSegment:0];
    [(NSSegmentedCell *)_zoomControls.cell setTag:0 forSegment:0];
    [(NSSegmentedCell *)_zoomControls.cell setToolTip:NSLocalizedStringWithDefaultValue(@"ZOOM_OUT_TOOLTIP", nil, nil, @"Zoom Out", @"Tooltip of Zoom Out button") forSegment:0];
    [_zoomControls setLabel:NSLocalizedStringWithDefaultValue(@"ZOOM_IN_LABEL", nil, nil, @"+", @"Label of Zoom In button") forSegment:1];
    [(NSSegmentedCell *)_zoomControls.cell setTag:1 forSegment:1];
    [(NSSegmentedCell *)_zoomControls.cell setToolTip:NSLocalizedStringWithDefaultValue(@"ZOOM_IN_TOOLTIP", nil, nil, @"Zoom In", @"Tooltip of Zoom In button") forSegment:1];
    _zoomControls.target = self;
    _zoomControls.action = @selector(zoomInOrOut:);
    _zoomControls.controlSize = NSControlSizeRegular;
    [_zoomControls sizeToFit];
    _zoomControls.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_zoomControls];
}

/// Adds a rudimentary compass control to the lower-right corner.
- (void)installCompass {
    _compass = [[NSSlider alloc] initWithFrame:NSZeroRect];
    _compass.wantsLayer = YES;
    _compass.layer.opacity = MHOrnamentOpacity;
    _compass.cell = [[MHCompassCell alloc] init];
    _compass.continuous = YES;
    _compass.target = self;
    _compass.action = @selector(rotate:);
    [_compass sizeToFit];
    _compass.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_compass];
}

/// Adds a Mapbox logo to the lower-left corner.
- (void)installLogoView {
    _logoView = [[NSImageView alloc] initWithFrame:NSZeroRect];
    _logoView.wantsLayer = YES;
    NSImage *logoImage = [[NSImage alloc] initWithContentsOfFile:
                          [[NSBundle mgl_frameworkBundle] pathForResource:@"mapbox" ofType:@"pdf"]];
    // Account for the image’s built-in padding when aligning other controls to the logo.
    logoImage.alignmentRect = NSOffsetRect(logoImage.alignmentRect, 0, 3);
    _logoView.image = logoImage;
    _logoView.translatesAutoresizingMaskIntoConstraints = NO;
    _logoView.accessibilityTitle = NSLocalizedStringWithDefaultValue(@"MAP_A11Y_TITLE", nil, nil, @"Mapbox", @"Accessibility title");
    [self addSubview:_logoView];
}

/// Adds legally required map attribution to the lower-left corner.
- (void)installAttributionView {
    [_attributionView removeFromSuperview];
    _attributionView = [[NSView alloc] initWithFrame:NSZeroRect];
    _attributionView.wantsLayer = YES;

    // Make the background and foreground translucent to be unobtrusive.
    _attributionView.layer.opacity = 0.6;

    // Blur the background to prevent text underneath the view from running into
    // the text in the view, rendering it illegible.
    CIFilter *attributionBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [attributionBlurFilter setDefaults];

    // Brighten the background. This is similar to applying a translucent white
    // background on the view, but the effect is a bit more subtle and works
    // well with the blur above.
    CIFilter *attributionColorFilter = [CIFilter filterWithName:@"CIColorControls"];
    [attributionColorFilter setDefaults];
    [attributionColorFilter setValue:@(0.1) forKey:kCIInputBrightnessKey];

    // Apply the background effects and a standard button corner radius.
    _attributionView.backgroundFilters = @[attributionColorFilter, attributionBlurFilter];
    _attributionView.layer.cornerRadius = 4;

    _attributionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_attributionView];
    [self updateAttributionView];
}

/// Adds gesture recognizers for manipulating the viewport and selecting annotations.
- (void)installGestureRecognizers {
    _scrollEnabled = YES;
    _zoomEnabled = YES;
    _rotateEnabled = YES;
    _pitchEnabled = YES;

    _panGestureRecognizer = [[NSPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    _panGestureRecognizer.delaysKeyEvents = YES;
    [self addGestureRecognizer:_panGestureRecognizer];

    _singleClickRecognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(handleClickGesture:)];
    _singleClickRecognizer.delaysPrimaryMouseButtonEvents = NO;
    _singleClickRecognizer.delegate = self;
    [self addGestureRecognizer:_singleClickRecognizer];

    NSClickGestureRecognizer *rightClickGestureRecognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightClickGesture:)];
    rightClickGestureRecognizer.buttonMask = 0x2;
    [self addGestureRecognizer:rightClickGestureRecognizer];

    NSClickGestureRecognizer *doubleClickGestureRecognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleClickGesture:)];
    doubleClickGestureRecognizer.numberOfClicksRequired = 2;
    doubleClickGestureRecognizer.delaysPrimaryMouseButtonEvents = NO;
    [self addGestureRecognizer:doubleClickGestureRecognizer];

    _magnificationGestureRecognizer = [[NSMagnificationGestureRecognizer alloc] initWithTarget:self action:@selector(handleMagnificationGesture:)];
    [self addGestureRecognizer:_magnificationGestureRecognizer];

    _rotationGestureRecognizer = [[NSRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotationGesture:)];
    [self addGestureRecognizer:_rotationGestureRecognizer];
}

/// Updates the attribution view to reflect the sources used. For now, this is
/// hard-coded to the standard Mapbox and OpenStreetMap attribution.
- (void)updateAttributionView {
    NSView *attributionView = self.attributionView;
    for (NSView *button in attributionView.subviews) {
        [button removeConstraints:button.constraints];
    }
    attributionView.subviews = @[];
    [attributionView removeConstraints:attributionView.constraints];

    // Make the whole string mini by default.
    // Force links to be black, because the default blue is distracting.
    CGFloat miniSize = [NSFont systemFontSizeForControlSize:NSControlSizeMini];
    NSArray *attributionInfos = [self.style attributionInfosWithFontSize:miniSize linkColor:[NSColor blackColor]];
    for (MHAttributionInfo *info in attributionInfos) {
        // Feedback links are added to the Help menu.
        if (info.feedbackLink) {
            continue;
        }

        // For each attribution, add a borderless button that responds to clicks
        // and feels like a hyperlink.
        NSButton *button = [[MHAttributionButton alloc] initWithAttributionInfo:info];
        button.controlSize = NSControlSizeMini;
        button.translatesAutoresizingMaskIntoConstraints = NO;

        // Set the new button flush with the buttom of the container and to the
        // right of the previous button, with standard spacing. If there is no
        // previous button, align to the container instead.
        NSView *previousView = attributionView.subviews.lastObject;
        [attributionView addSubview:button];
        [attributionView addConstraint:
         [NSLayoutConstraint constraintWithItem:button
                                      attribute:NSLayoutAttributeBottom
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:attributionView
                                      attribute:NSLayoutAttributeBottom
                                     multiplier:1
                                       constant:0]];
        [attributionView addConstraint:
         [NSLayoutConstraint constraintWithItem:button
                                      attribute:NSLayoutAttributeLeading
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:previousView ? previousView : attributionView
                                      attribute:previousView ? NSLayoutAttributeTrailing : NSLayoutAttributeLeading
                                     multiplier:1
                                       constant:8]];
        [attributionView addConstraint:
         [NSLayoutConstraint constraintWithItem:button
                                      attribute:NSLayoutAttributeTop
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:attributionView
                                      attribute:NSLayoutAttributeTop
                                     multiplier:1
                                       constant:0]];
    }

    if (attributionInfos.count) {
        [attributionView addConstraint:
         [NSLayoutConstraint constraintWithItem:attributionView
                                      attribute:NSLayoutAttributeTrailing
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:attributionView.subviews.lastObject
                                      attribute:NSLayoutAttributeTrailing
                                     multiplier:1
                                       constant:8]];
    }
}

- (void)dealloc {

    [_reachability stopNotifier];


    [self.window removeObserver:self forKeyPath:@"contentLayoutRect"];
    [self.window removeObserver:self forKeyPath:@"titlebarAppearsTransparent"];

    // Close any annotation callout immediately.
    [self.calloutForSelectedAnnotation close];
    self.calloutForSelectedAnnotation = nil;

    // Removing the annotations unregisters any outstanding KVO observers.
    [self removeAnnotations:self.annotations];

    _mbglMap.reset();
    _mbglView.reset();
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(__unused NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentLayoutRect"] ||
        [keyPath isEqualToString:@"titlebarAppearsTransparent"]) {
        [self adjustContentInsets];
    } else if ([keyPath isEqualToString:@"coordinate"] &&
               [object conformsToProtocol:@protocol(MHAnnotation)] &&
               ![object isKindOfClass:[MHMultiPoint class]]) {
        id <MHAnnotation> annotation = object;
        MHAnnotationTag annotationTag = (MHAnnotationTag)(NSUInteger)context;
        // We can get here because a subclass registered itself as an observer
        // of the coordinate key path of a non-multipoint annotation but failed
        // to handle the change. This check deters us from treating the
        // subclass’s context as an annotation tag. If the context happens to
        // match a valid annotation tag, the annotation will be unnecessarily
        // but safely updated.
        if (annotation == [self annotationWithTag:annotationTag]) {
            const mbgl::Point<double> point = MHPointFeatureClusterFromLocationCoordinate2D(annotation.coordinate);
            MHAnnotationImage *annotationImage = [self imageOfAnnotationWithTag:annotationTag];
            _mbglMap->updateAnnotation(annotationTag, mbgl::SymbolAnnotation { point, annotationImage.styleIconIdentifier.UTF8String ?: "" });
            [self updateAnnotationCallouts];
        }
    } else if ([keyPath isEqualToString:@"coordinates"] &&
               [object isKindOfClass:[MHMultiPoint class]]) {
        MHMultiPoint *annotation = object;
        MHAnnotationTag annotationTag = (MHAnnotationTag)(NSUInteger)context;
        // We can get here because a subclass registered itself as an observer
        // of the coordinates key path of a multipoint annotation but failed
        // to handle the change. This check deters us from treating the
        // subclass’s context as an annotation tag. If the context happens to
        // match a valid annotation tag, the annotation will be unnecessarily
        // but safely updated.
        if (annotation == [self annotationWithTag:annotationTag]) {
            _mbglMap->updateAnnotation(annotationTag, [annotation annotationObjectWithDelegate:self]);
            [self updateAnnotationCallouts];
        }
    }
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    return [key isEqualToString:@"annotations"] ? YES : [super automaticallyNotifiesObserversForKey:key];
}

- (void)setDelegate:(id<MHMapViewDelegate>)delegate {
    _delegate = delegate;

    // Cache checks for delegate method implementations that may be called in a
    // hot loop, namely the annotation style methods.
    _delegateHasAlphasForShapeAnnotations = [_delegate respondsToSelector:@selector(mapView:alphaForShapeAnnotation:)];
    _delegateHasStrokeColorsForShapeAnnotations = [_delegate respondsToSelector:@selector(mapView:strokeColorForShapeAnnotation:)];
    _delegateHasFillColorsForShapeAnnotations = [_delegate respondsToSelector:@selector(mapView:fillColorForPolygonAnnotation:)];
    _delegateHasLineWidthsForShapeAnnotations = [_delegate respondsToSelector:@selector(mapView:lineWidthForPolylineAnnotation:)];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self.delegate respondsToSelector:@selector(mapView:regionWillChangeAnimated:)]) {
        NSLog(@"-mapView:regionWillChangeAnimated: is not supported by the macOS SDK, but %@ implements it anyways. "
              @"Please implement -[%@ mapView:cameraWillChangeAnimated:] instead.",
              NSStringFromClass([delegate class]), NSStringFromClass([delegate class]));
    }
    if ([self.delegate respondsToSelector:@selector(mapViewRegionIsChanging:)]) {
        NSLog(@"-mapViewRegionIsChanging: is not supported by the macOS SDK, but %@ implements it anyways. "
              @"Please implement -[%@ mapViewCameraIsChanging:] instead.",
              NSStringFromClass([delegate class]), NSStringFromClass([delegate class]));
    }
    if ([self.delegate respondsToSelector:@selector(mapView:regionDidChangeAnimated:)]) {
        NSLog(@"-mapView:regionDidChangeAnimated: is not supported by the macOS SDK, but %@ implements it anyways. "
              @"Please implement -[%@ mapView:cameraDidChangeAnimated:] instead.",
              NSStringFromClass([delegate class]), NSStringFromClass([delegate class]));
    }
#pragma clang diagnostic pop
}

// MARK: Style

+ (NSSet<NSString *> *)keyPathsForValuesAffectingStyle {
    return [NSSet setWithObject:@"styleURL"];
}

- (nonnull NSURL *)styleURL {
    NSString *styleURLString = @(_mbglMap->getStyle().getURL().c_str()).mgl_stringOrNilIfEmpty;
    return styleURLString ? [NSURL URLWithString:styleURLString] : [MHStyle defaultStyleURL];
}

- (void)setStyleURL:(nullable NSURL *)styleURL {
    if (_isTargetingInterfaceBuilder) {
        return;
    }

    if (!styleURL) {
        styleURL = [MHStyle defaultStyleURL];
    }
    MHLogDebug(@"Setting styleURL: %@", styleURL);

    // An access token is required to load any default style, including Streets.
    if ([[MHSettings sharedSettings] tileServerOptionsInternal]->requiresApiKey() && ![MHSettings apiKey]) {
        NSLog(@"Cannot set the style URL to %@ because no API key has been specified.", styleURL);
        return;
    }

    styleURL = styleURL.mgl_URLByStandardizingScheme;
    self.style = nil;
    _mbglMap->getStyle().loadURL(styleURL.absoluteString.UTF8String);
}

- (IBAction)reloadStyle:(__unused id)sender {
    MHLogInfo(@"Reloading style.");
    NSURL *styleURL = self.styleURL;
    _mbglMap->getStyle().loadURL("");
    self.styleURL = styleURL;
}

- (void)setPrefetchesTiles:(BOOL)prefetchesTiles
{
    _mbglMap->setPrefetchZoomDelta(prefetchesTiles ? mbgl::util::DEFAULT_PREFETCH_ZOOM_DELTA : 0);
}

- (BOOL)prefetchesTiles
{
    return _mbglMap->getPrefetchZoomDelta() > 0 ? YES : NO;
}

- (mbgl::Renderer *)renderer {
    return _rendererFrontend->getRenderer();
}

// MARK: View hierarchy and drawing

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    [self deselectAnnotation:self.selectedAnnotation];
    if (!self.dormant && !newWindow) {
        self.dormant = YES;
    }

    [self.window removeObserver:self forKeyPath:@"contentLayoutRect"];
    [self.window removeObserver:self forKeyPath:@"titlebarAppearsTransparent"];
}

- (void)viewDidMoveToWindow {
    NSWindow *window = self.window;
    if (self.dormant && window) {
        self.dormant = NO;
    }

    if (window && _mbglMap->getMapOptions().constrainMode() == mbgl::ConstrainMode::None) {
        _mbglMap->setConstrainMode(mbgl::ConstrainMode::HeightOnly);
    }

    [window addObserver:self
             forKeyPath:@"contentLayoutRect"
                options:NSKeyValueObservingOptionInitial
                context:NULL];
    [window addObserver:self
             forKeyPath:@"titlebarAppearsTransparent"
                options:NSKeyValueObservingOptionInitial
                context:NULL];
}

- (BOOL)wantsLayer {
    return YES;
}

- (BOOL)wantsBestResolutionOpenGLSurface {
    // Use an OpenGL layer, except when drawing the designable, which is just
    // ordinary Cocoa.
    return !_isTargetingInterfaceBuilder;
}

- (CGLContextObj)context {
    return _mbglView->getCGLContextObj();
}

- (void)setFrame:(NSRect)frame {
    super.frame = frame;
    if (!_isTargetingInterfaceBuilder) {
        _mbglMap->setSize(self.size);
    }
}

- (void)updateConstraints {
    // Place the zoom controls at the lower-right corner of the view.
    [self addConstraint:
     [NSLayoutConstraint constraintWithItem:self
                                  attribute:NSLayoutAttributeBottom
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:_zoomControls
                                  attribute:NSLayoutAttributeBottom
                                 multiplier:1
                                   constant:MHOrnamentPadding]];
    [self addConstraint:
     [NSLayoutConstraint constraintWithItem:self
                                  attribute:NSLayoutAttributeTrailing
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:_zoomControls
                                  attribute:NSLayoutAttributeTrailing
                                 multiplier:1
                                   constant:MHOrnamentPadding]];

    // Center the compass above the zoom controls, assuming that the compass is
    // narrower than the zoom controls.
    [self addConstraint:
     [NSLayoutConstraint constraintWithItem:_compass
                                  attribute:NSLayoutAttributeCenterX
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:_zoomControls
                                  attribute:NSLayoutAttributeCenterX
                                 multiplier:1
                                   constant:0]];
    [self addConstraint:
     [NSLayoutConstraint constraintWithItem:_zoomControls
                                  attribute:NSLayoutAttributeTop
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:_compass
                                  attribute:NSLayoutAttributeBottom
                                 multiplier:1
                                   constant:8]];

    // Place the logo view in the lower-left corner of the view, accounting for
    // the logo’s alignment rect.
    [self addConstraint:
     [NSLayoutConstraint constraintWithItem:self
                                  attribute:NSLayoutAttributeBottom
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:_logoView
                                  attribute:NSLayoutAttributeBottom
                                 multiplier:1
                                   constant:MHOrnamentPadding - _logoView.image.alignmentRect.origin.y]];
    [self addConstraint:
     [NSLayoutConstraint constraintWithItem:_logoView
                                  attribute:NSLayoutAttributeLeading
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self
                                  attribute:NSLayoutAttributeLeading
                                 multiplier:1
                                   constant:MHOrnamentPadding - _logoView.image.alignmentRect.origin.x]];

    // Place the attribution view to the right of the logo view and size it to
    // fit the buttons inside.
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_logoView
                                                     attribute:NSLayoutAttributeBaseline
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:_attributionView
                                                     attribute:NSLayoutAttributeBaseline
                                                    multiplier:1
                                                      constant:_logoView.image.alignmentRect.origin.y]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_attributionView
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:_logoView
                                                     attribute:NSLayoutAttributeTrailing
                                                    multiplier:1
                                                      constant:8]];

    [super updateConstraints];
}

- (void)renderSync {
    if (!self.dormant && _rendererFrontend) {
        _rendererFrontend->render();

        if (_isPrinting) {
            _isPrinting = NO;
            NSImage *image = [[NSImage alloc] initWithMHPremultipliedImage:_mbglView->readStillImage()];
            [self performSelector:@selector(printWithImage:) withObject:image afterDelay:0];
        }

//        [self updateUserLocationAnnotationView];
    }
}

- (BOOL)isTargetingInterfaceBuilder {
    return _isTargetingInterfaceBuilder;
}

- (void)setNeedsRerender {
    MHAssertIsMainThread();

    [self.layer setNeedsDisplay];
}

- (void)cameraWillChangeAnimated:(BOOL)animated {
    if (!_mbglMap) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(mapView:cameraWillChangeAnimated:)]) {
        [self.delegate mapView:self cameraWillChangeAnimated:animated];
    }
}

- (void)cameraIsChanging {
    if (!_mbglMap) {
        return;
    }

    // Update a minimum of UI that needs to stay attached to the map
    // while animating.
    [self updateCompass];
    [self updateAnnotationCallouts];

    if ([self.delegate respondsToSelector:@selector(mapViewCameraIsChanging:)]) {
        [self.delegate mapViewCameraIsChanging:self];
    }
}

- (void)cameraDidChangeAnimated:(BOOL)animated {
    if (!_mbglMap) {
        return;
    }

    // Update all UI at the end of an animation or atomic change to the
    // viewport. More expensive updates can happen here, but care should
    // still be taken to minimize the work done here because scroll
    // gesture recognition and momentum scrolling is performed as a
    // series of atomic changes, not an animation.
    [self updateZoomControls];
    [self updateCompass];
    [self updateAnnotationCallouts];
    [self updateAnnotationTrackingAreas];

    if ([self.delegate respondsToSelector:@selector(mapView:cameraDidChangeAnimated:)]) {
        [self.delegate mapView:self cameraDidChangeAnimated:animated];
    }
}

- (void)mapViewWillStartLoadingMap {
    if (!_mbglMap) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(mapViewWillStartLoadingMap:)]) {
        [self.delegate mapViewWillStartLoadingMap:self];
    }
}

- (void)mapViewDidFinishLoadingMap {
    if (!_mbglMap) {
        return;
    }

    [self.style willChangeValueForKey:@"sources"];
    [self.style didChangeValueForKey:@"sources"];
    [self.style willChangeValueForKey:@"layers"];
    [self.style didChangeValueForKey:@"layers"];
    if ([self.delegate respondsToSelector:@selector(mapViewDidFinishLoadingMap:)]) {
        [self.delegate mapViewDidFinishLoadingMap:self];
    }
}

- (void)mapViewDidFailLoadingMapWithError:(NSError *)error {
    if (!_mbglMap) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(mapViewDidFailLoadingMap:withError:)]) {
        [self.delegate mapViewDidFailLoadingMap:self withError:error];
    }
}

- (void)mapViewWillStartRenderingFrame {
    if (!_mbglMap) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(mapViewWillStartRenderingFrame:)]) {
        [self.delegate mapViewWillStartRenderingFrame:self];
    }
}

- (void)mapViewDidFinishRenderingFrameFullyRendered:(BOOL)fullyRendered {
    if (!_mbglMap) {
        return;
    }

    if (_isChangingAnnotationLayers) {
        _isChangingAnnotationLayers = NO;
        [self.style didChangeValueForKey:@"layers"];
    }
    if ([self.delegate respondsToSelector:@selector(mapViewDidFinishRenderingFrame:fullyRendered:)]) {
        [self.delegate mapViewDidFinishRenderingFrame:self fullyRendered:fullyRendered];
    }
}

- (void)mapViewWillStartRenderingMap {
    if (!_mbglMap) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(mapViewWillStartRenderingMap:)]) {
        [self.delegate mapViewWillStartRenderingMap:self];
    }
}

- (void)mapViewDidFinishRenderingMapFullyRendered:(BOOL)fullyRendered {
    if (!_mbglMap) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(mapViewDidFinishRenderingMap:fullyRendered:)]) {
        [self.delegate mapViewDidFinishRenderingMap:self fullyRendered:fullyRendered];
    }
}

- (void)mapViewDidBecomeIdle {
    if (!_mbglMap) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(mapViewDidBecomeIdle:)]) {
        [self.delegate mapViewDidBecomeIdle:self];
    }
}

- (void)mapViewDidFinishLoadingStyle {
    if (!_mbglMap) {
        return;
    }

    self.style = [[MHStyle alloc] initWithRawStyle:&_mbglMap->getStyle() stylable:self];
    if ([self.delegate respondsToSelector:@selector(mapView:didFinishLoadingStyle:)])
    {
        [self.delegate mapView:self didFinishLoadingStyle:self.style];
    }
}

- (void)sourceDidChange:(MHSource *)source {
    if (!_mbglMap) {
        return;
    }
    // Attribution only applies to tiled sources
    if ([source isKindOfClass:[MHTileSource class]]) {
        [self installAttributionView];
    }
    self.needsUpdateConstraints = YES;
    self.needsDisplay = YES;
}

- (BOOL)shouldRemoveStyleImage:(NSString *)imageName {
    if ([self.delegate respondsToSelector:@selector(mapView:shouldRemoveStyleImage:)]) {
        return [self.delegate mapView:self shouldRemoveStyleImage:imageName];
    }
    
    return YES;
}

// MARK: Printing

- (void)print:(__unused id)sender {
    _isPrinting = YES;
    [self setNeedsRerender];
}

- (void)printWithImage:(NSImage *)image {
    NSImageView *imageView = [[NSImageView alloc] initWithFrame:self.bounds];
    imageView.image = image;

    NSPrintOperation *op = [NSPrintOperation printOperationWithView:imageView];
    [op runOperation];
}

// MARK: Viewport

+ (NSSet<NSString *> *)keyPathsForValuesAffectingCenterCoordinate {
    return [NSSet setWithObjects:@"latitude", @"longitude", @"camera", nil];
}

- (CLLocationCoordinate2D)centerCoordinate {
    mbgl::EdgeInsets padding = MHEdgeInsetsFromNSEdgeInsets(self.contentInsets);
    return MHLocationCoordinate2DFromLatLng(*_mbglMap->getCameraOptions(padding).center);
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate {
    MHLogDebug(@"Setting centerCoordinate: %@", MHStringFromCLLocationCoordinate2D(centerCoordinate));
    [self setCenterCoordinate:centerCoordinate animated:NO];
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate animated:(BOOL)animated {
    [self setCenterCoordinate:centerCoordinate animated:animated completionHandler:nil];
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate animated:(BOOL)animated completionHandler:(nullable void (^)(void))completion {
    MHLogDebug(@"Setting centerCoordinate: %@ animated: %@", MHStringFromCLLocationCoordinate2D(centerCoordinate), MHStringFromBOOL(animated));
    mbgl::AnimationOptions animationOptions = MHDurationFromTimeInterval(animated ? MHAnimationDuration : 0);
    animationOptions.transitionFinishFn = ^() {
        [self didChangeValueForKey:@"centerCoordinate"];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    };
    
    [self willChangeValueForKey:@"centerCoordinate"];
    _mbglMap->easeTo(mbgl::CameraOptions()
                         .withCenter(MHLatLngFromLocationCoordinate2D(centerCoordinate))
                         .withPadding(MHEdgeInsetsFromNSEdgeInsets(self.contentInsets)),
                     animationOptions);
}

- (void)offsetCenterCoordinateBy:(NSPoint)delta animated:(BOOL)animated {
    [self willChangeValueForKey:@"centerCoordinate"];
    _mbglMap->cancelTransitions();
    MHMapCamera *oldCamera = self.camera;
    _mbglMap->moveBy({ delta.x, delta.y },
                     MHDurationFromTimeInterval(animated ? MHAnimationDuration : 0));
    if ([self.delegate respondsToSelector:@selector(mapView:shouldChangeFromCamera:toCamera:)]
        && ![self.delegate mapView:self shouldChangeFromCamera:oldCamera toCamera:self.camera]) {
        self.camera = oldCamera;
    }
    [self didChangeValueForKey:@"centerCoordinate"];
}

- (CLLocationDegrees)pendingLatitude {
    return _pendingLatitude;
}

- (void)setPendingLatitude:(CLLocationDegrees)pendingLatitude {
    _pendingLatitude = pendingLatitude;
}

- (CLLocationDegrees)pendingLongitude {
    return _pendingLongitude;
}

- (void)setPendingLongitude:(CLLocationDegrees)pendingLongitude {
    _pendingLongitude = pendingLongitude;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingZoomLevel {
    return [NSSet setWithObject:@"camera"];
}

- (double)zoomLevel {
    mbgl::EdgeInsets padding = MHEdgeInsetsFromNSEdgeInsets(self.contentInsets);
    return *_mbglMap->getCameraOptions(padding).zoom;
}

- (void)setZoomLevel:(double)zoomLevel {
    MHLogDebug(@"Setting zoomLevel: %f", zoomLevel);
    [self setZoomLevel:zoomLevel animated:NO];
}

- (void)setZoomLevel:(double)zoomLevel animated:(BOOL)animated {
    MHLogDebug(@"Setting zoomLevel: %f animated: %@", zoomLevel, MHStringFromBOOL(animated));
    [self willChangeValueForKey:@"zoomLevel"];
    _mbglMap->easeTo(mbgl::CameraOptions()
                         .withZoom(zoomLevel)
                         .withPadding(MHEdgeInsetsFromNSEdgeInsets(self.contentInsets)),
                     MHDurationFromTimeInterval(animated ? MHAnimationDuration : 0));
    [self didChangeValueForKey:@"zoomLevel"];
}

- (void)setZoomLevel:(double)zoomLevel atPoint:(NSPoint)point animated:(BOOL)animated {
    [self willChangeValueForKey:@"centerCoordinate"];
    [self willChangeValueForKey:@"zoomLevel"];
    MHMapCamera *oldCamera = self.camera;
    mbgl::ScreenCoordinate center(point.x, self.bounds.size.height - point.y);
    _mbglMap->easeTo(mbgl::CameraOptions()
                         .withZoom(zoomLevel)
                         .withAnchor(center),
                     MHDurationFromTimeInterval(animated ? MHAnimationDuration : 0));
    if ([self.delegate respondsToSelector:@selector(mapView:shouldChangeFromCamera:toCamera:)]
        && ![self.delegate mapView:self shouldChangeFromCamera:oldCamera toCamera:self.camera]) {
        self.camera = oldCamera;
    }
    [self didChangeValueForKey:@"zoomLevel"];
    [self didChangeValueForKey:@"centerCoordinate"];
}

- (void)setMinimumZoomLevel:(double)minimumZoomLevel
{
    MHLogDebug(@"Setting minimumZoomLevel: %f", minimumZoomLevel);
    _mbglMap->setBounds(mbgl::BoundOptions().withMinZoom(minimumZoomLevel));
}

- (void)setMaximumZoomLevel:(double)maximumZoomLevel
{
    MHLogDebug(@"Setting maximumZoomLevel: %f", maximumZoomLevel);
    _mbglMap->setBounds(mbgl::BoundOptions().withMaxZoom(maximumZoomLevel));
}

- (double)maximumZoomLevel {
    return *_mbglMap->getBounds().maxZoom;
}

- (double)minimumZoomLevel {
    return *_mbglMap->getBounds().minZoom;
}

/// Respond to a click on the zoom control.
- (IBAction)zoomInOrOut:(NSSegmentedControl *)sender {
    switch (sender.selectedSegment) {
        case 0:
            // Zoom out.
            [self moveToEndOfParagraph:sender];
            break;
        case 1:
            // Zoom in.
            [self moveToBeginningOfParagraph:sender];
            break;
        default:
            break;
    }
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingDirection {
    return [NSSet setWithObject:@"camera"];
}

- (CLLocationDirection)direction {
    return mbgl::util::wrap(*_mbglMap->getCameraOptions().bearing, 0., 360.);
}

- (void)setDirection:(CLLocationDirection)direction {
    MHLogDebug(@"Setting direction: %f", direction);
    [self setDirection:direction animated:NO];
}

- (void)setDirection:(CLLocationDirection)direction animated:(BOOL)animated {
    MHLogDebug(@"Setting direction: %f animated: %@", direction, MHStringFromBOOL(animated));
    [self willChangeValueForKey:@"direction"];
    _mbglMap->easeTo(mbgl::CameraOptions()
                         .withBearing(direction)
                         .withPadding(MHEdgeInsetsFromNSEdgeInsets(self.contentInsets)),
                     MHDurationFromTimeInterval(animated ? MHAnimationDuration : 0));
    [self didChangeValueForKey:@"direction"];
}

- (void)offsetDirectionBy:(CLLocationDegrees)delta animated:(BOOL)animated {
    [self setDirection:*_mbglMap->getCameraOptions().bearing + delta animated:animated];
}

- (CGFloat)minimumPitch {
    return *_mbglMap->getBounds().minPitch;
}

- (void)setMinimumPitch:(CGFloat)minimumPitch {
    MHLogDebug(@"Setting minimumPitch: %f", minimumPitch);
    _mbglMap->setBounds(mbgl::BoundOptions().withMinPitch(minimumPitch));
}

- (CGFloat)maximumPitch {
    return *_mbglMap->getBounds().maxPitch;
}

- (void)setMaximumPitch:(CGFloat)maximumPitch {
    MHLogDebug(@"Setting maximumPitch: %f", maximumPitch);
    _mbglMap->setBounds(mbgl::BoundOptions().withMaxPitch(maximumPitch));
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingCamera {
    return [NSSet setWithObjects:@"latitude", @"longitude", @"centerCoordinate", @"zoomLevel", @"direction", nil];
}

- (MHMapCamera *)camera {
    mbgl::EdgeInsets padding = MHEdgeInsetsFromNSEdgeInsets(self.contentInsets);
    return [self cameraForCameraOptions:_mbglMap->getCameraOptions(padding)];
}

- (void)setCamera:(MHMapCamera *)camera {
    MHLogDebug(@"Setting camera: %@", camera);
    [self setCamera:camera animated:NO];
}

- (void)setCamera:(MHMapCamera *)camera animated:(BOOL)animated {
    MHLogDebug(@"Setting camera: %@ animated: %@", camera, MHStringFromBOOL(animated));
    [self setCamera:camera withDuration:animated ? MHAnimationDuration : 0 animationTimingFunction:nil completionHandler:NULL];
}

- (void)setCamera:(MHMapCamera *)camera withDuration:(NSTimeInterval)duration animationTimingFunction:(nullable CAMediaTimingFunction *)function completionHandler:(nullable void (^)(void))completion {
    MHLogDebug(@"Setting camera: %@ duration: %f animationTimingFunction: %@", camera, duration, function);
    [self setCamera:camera withDuration:duration animationTimingFunction:function edgePadding:NSEdgeInsetsZero completionHandler:completion];
}

- (void)setCamera:(MHMapCamera *)camera withDuration:(NSTimeInterval)duration animationTimingFunction:(nullable CAMediaTimingFunction *)function edgePadding:(NSEdgeInsets)edgePadding completionHandler:(nullable void (^)(void))completion {
    edgePadding = MHEdgeInsetsInsetEdgeInset(edgePadding, self.contentInsets);
    mbgl::AnimationOptions animationOptions;
    if (duration > 0) {
        animationOptions.duration.emplace(MHDurationFromTimeInterval(duration));
        animationOptions.easing.emplace(MHUnitBezierForMediaTimingFunction(function));
    }
    if (completion) {
        animationOptions.transitionFinishFn = [completion]() {
            // Must run asynchronously after the transition is completely over.
            // Otherwise, a call to -setCamera: within the completion handler
            // would reenter the completion handler’s caller.
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        };
    }
    
    if ([self.camera isEqualToMapCamera:camera]) {
        if (completion) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                completion();
            });
        }
        return;
    }

    [self willChangeValueForKey:@"camera"];
    _mbglMap->cancelTransitions();
    mbgl::CameraOptions cameraOptions = [self cameraOptionsObjectForAnimatingToCamera:camera edgePadding:edgePadding];
    _mbglMap->easeTo(cameraOptions, animationOptions);
    [self didChangeValueForKey:@"camera"];
}

- (void)flyToCamera:(MHMapCamera *)camera completionHandler:(nullable void (^)(void))completion {
    MHLogDebug(@"Setting flyToCamera: %@ completionHandler: %@", camera, completion);
    [self flyToCamera:camera withDuration:-1 completionHandler:completion];
}

- (void)flyToCamera:(MHMapCamera *)camera withDuration:(NSTimeInterval)duration completionHandler:(nullable void (^)(void))completion {
    MHLogDebug(@"Setting flyToCamera: %@ withDuration: %f completionHandler: %@", camera, duration, completion);
    [self flyToCamera:camera withDuration:duration peakAltitude:-1 completionHandler:completion];
}

- (void)flyToCamera:(MHMapCamera *)camera withDuration:(NSTimeInterval)duration peakAltitude:(CLLocationDistance)peakAltitude completionHandler:(nullable void (^)(void))completion {
    MHLogDebug(@"Setting flyToCamera: %@ withDuration: %f peakAltitude: %f completionHandler: %@", camera, duration, peakAltitude, completion);
    mbgl::AnimationOptions animationOptions;
    if (duration >= 0) {
        animationOptions.duration = MHDurationFromTimeInterval(duration);
    }
    if (peakAltitude >= 0) {
        CLLocationDegrees peakLatitude = (self.centerCoordinate.latitude + camera.centerCoordinate.latitude) / 2;
        CLLocationDegrees peakPitch = (self.camera.pitch + camera.pitch) / 2;
        animationOptions.minZoom = MHZoomLevelForAltitude(peakAltitude, peakPitch,
                                                           peakLatitude, self.frame.size);
    }
    if (completion) {
        animationOptions.transitionFinishFn = [completion]() {
            // Must run asynchronously after the transition is completely over.
            // Otherwise, a call to -setCamera: within the completion handler
            // would reenter the completion handler’s caller.
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        };
    }
    
    if ([self.camera isEqualToMapCamera:camera]) {
        if (completion) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                completion();
            });
        }
        return;
    }

    [self willChangeValueForKey:@"camera"];
    _mbglMap->cancelTransitions();
    mbgl::CameraOptions cameraOptions = [self cameraOptionsObjectForAnimatingToCamera:camera edgePadding:self.contentInsets];
    _mbglMap->flyTo(cameraOptions, animationOptions);
    [self didChangeValueForKey:@"camera"];
}

/// Returns a CameraOptions object that specifies parameters for animating to
/// the given camera.
- (mbgl::CameraOptions)cameraOptionsObjectForAnimatingToCamera:(MHMapCamera *)camera edgePadding:(NSEdgeInsets) edgePadding {
    mbgl::CameraOptions options;
    options.center = MHLatLngFromLocationCoordinate2D(camera.centerCoordinate);
    options.padding = MHEdgeInsetsFromNSEdgeInsets(edgePadding);
    options.zoom = MHZoomLevelForAltitude(camera.altitude, camera.pitch,
                                           camera.centerCoordinate.latitude,
                                           self.frame.size);
    if (camera.heading >= 0) {
        options.bearing = camera.heading;
    }
    if (camera.pitch >= 0) {
        options.pitch = camera.pitch;
    }
    return options;
}

+ (NSSet *)keyPathsForValuesAffectingVisibleCoordinateBounds {
    return [NSSet setWithObjects:@"centerCoordinate", @"zoomLevel", @"direction", @"bounds", nil];
}

- (MHCoordinateBounds)visibleCoordinateBounds {
    return [self convertRect:self.bounds toCoordinateBoundsFromView:self];
}

- (void)setVisibleCoordinateBounds:(MHCoordinateBounds)bounds {
    MHLogDebug(@"Setting visibleCoordinateBounds: %@", MHStringFromCoordinateBounds(bounds));
    [self setVisibleCoordinateBounds:bounds animated:NO];
}

- (void)setVisibleCoordinateBounds:(MHCoordinateBounds)bounds animated:(BOOL)animated {
    MHLogDebug(@"Setting visibleCoordinateBounds: %@ animated: %@", MHStringFromCoordinateBounds(bounds), MHStringFromBOOL(animated));
    [self setVisibleCoordinateBounds:bounds edgePadding:NSEdgeInsetsZero animated:animated];
}

- (void)setVisibleCoordinateBounds:(MHCoordinateBounds)bounds edgePadding:(NSEdgeInsets)insets animated:(BOOL)animated {
    [self setVisibleCoordinateBounds:bounds edgePadding:insets animated:animated completionHandler:nil];
}

- (void)setVisibleCoordinateBounds:(MHCoordinateBounds)bounds edgePadding:(NSEdgeInsets)insets animated:(BOOL)animated completionHandler:(nullable void (^)(void))completion {
    _mbglMap->cancelTransitions();

    mbgl::EdgeInsets padding = MHEdgeInsetsFromNSEdgeInsets(insets);
    padding += MHEdgeInsetsFromNSEdgeInsets(self.contentInsets);
    mbgl::CameraOptions cameraOptions = _mbglMap->cameraForLatLngBounds(MHLatLngBoundsFromCoordinateBounds(bounds), padding);
    mbgl::AnimationOptions animationOptions;
    if (animated) {
        animationOptions.duration = MHDurationFromTimeInterval(MHAnimationDuration);
    }
    
    MHMapCamera *camera = [self cameraForCameraOptions:cameraOptions];
    if ([self.camera isEqualToMapCamera:camera]) {
        completion();
        return;
    }

    [self willChangeValueForKey:@"visibleCoordinateBounds"];
    animationOptions.transitionFinishFn = ^() {
        [self didChangeValueForKey:@"visibleCoordinateBounds"];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    };
    _mbglMap->easeTo(cameraOptions, animationOptions);
}

- (MHMapCamera *)cameraThatFitsCoordinateBounds:(MHCoordinateBounds)bounds {
    return [self cameraThatFitsCoordinateBounds:bounds edgePadding:NSEdgeInsetsZero];
}

- (MHMapCamera *)cameraThatFitsCoordinateBounds:(MHCoordinateBounds)bounds edgePadding:(NSEdgeInsets)insets {
    mbgl::EdgeInsets padding = MHEdgeInsetsFromNSEdgeInsets(insets);
    padding += MHEdgeInsetsFromNSEdgeInsets(self.contentInsets);
    mbgl::CameraOptions cameraOptions = _mbglMap->cameraForLatLngBounds(MHLatLngBoundsFromCoordinateBounds(bounds), padding);
    return [self cameraForCameraOptions:cameraOptions];
}

- (MHMapCamera *)camera:(MHMapCamera *)camera fittingCoordinateBounds:(MHCoordinateBounds)bounds edgePadding:(NSEdgeInsets)insets
{
    mbgl::EdgeInsets padding = MHEdgeInsetsFromNSEdgeInsets(insets);
    padding += MHEdgeInsetsFromNSEdgeInsets(self.contentInsets);
    
    MHMapCamera *currentCamera = self.camera;
    CGFloat pitch = camera.pitch < 0 ? currentCamera.pitch : camera.pitch;
    CLLocationDirection direction = camera.heading < 0 ? currentCamera.heading : camera.heading;
    
    mbgl::CameraOptions cameraOptions = _mbglMap->cameraForLatLngBounds(MHLatLngBoundsFromCoordinateBounds(bounds), padding, direction, pitch);
    return [self cameraForCameraOptions:cameraOptions];
}

- (MHMapCamera *)camera:(MHMapCamera *)camera fittingShape:(MHShape *)shape edgePadding:(NSEdgeInsets)insets {
    mbgl::EdgeInsets padding = MHEdgeInsetsFromNSEdgeInsets(insets);
    padding += MHEdgeInsetsFromNSEdgeInsets(self.contentInsets);
    
    MHMapCamera *currentCamera = self.camera;
    CGFloat pitch = camera.pitch < 0 ? currentCamera.pitch : camera.pitch;
    CLLocationDirection direction = camera.heading < 0 ? currentCamera.heading : camera.heading;
    
    mbgl::CameraOptions cameraOptions = _mbglMap->cameraForGeometry([shape geometryObject], padding, direction, pitch);
    
    return [self cameraForCameraOptions: cameraOptions];
}

- (MHMapCamera *)cameraThatFitsShape:(MHShape *)shape direction:(CLLocationDirection)direction edgePadding:(NSEdgeInsets)insets {
    mbgl::EdgeInsets padding = MHEdgeInsetsFromNSEdgeInsets(insets);
    padding += MHEdgeInsetsFromNSEdgeInsets(self.contentInsets);

    mbgl::CameraOptions cameraOptions = _mbglMap->cameraForGeometry([shape geometryObject], padding, direction);

    return [self cameraForCameraOptions:cameraOptions];
}

- (MHMapCamera *)cameraForCameraOptions:(const mbgl::CameraOptions &)cameraOptions {
    mbgl::CameraOptions mapCamera = _mbglMap->getCameraOptions();
    CLLocationCoordinate2D centerCoordinate = MHLocationCoordinate2DFromLatLng(cameraOptions.center ? *cameraOptions.center : *mapCamera.center);
    double zoomLevel = cameraOptions.zoom ? *cameraOptions.zoom : self.zoomLevel;
    CLLocationDirection direction = cameraOptions.bearing ? mbgl::util::wrap(*cameraOptions.bearing, 0., 360.) : self.direction;
    CGFloat pitch = cameraOptions.pitch ? *cameraOptions.pitch : *mapCamera.pitch;
    CLLocationDistance altitude = MHAltitudeForZoomLevel(zoomLevel, pitch,
                                                          centerCoordinate.latitude,
                                                          self.frame.size);
    return [MHMapCamera cameraLookingAtCenterCoordinate:centerCoordinate
                                                altitude:altitude
                                                   pitch:pitch
                                                 heading:direction];
}

- (void)setAutomaticallyAdjustsContentInsets:(BOOL)automaticallyAdjustsContentInsets {
    _automaticallyAdjustsContentInsets = automaticallyAdjustsContentInsets;
    [self adjustContentInsets];
}

/// Updates `contentInsets` to reflect the current window geometry.
- (void)adjustContentInsets {
    if (!_automaticallyAdjustsContentInsets) {
        return;
    }

    NSEdgeInsets contentInsets = self.contentInsets;
    if ((self.window.styleMask & NSWindowStyleMaskFullSizeContentView)
        && !self.window.titlebarAppearsTransparent) {
        NSRect contentLayoutRect = [self convertRect:self.window.contentLayoutRect fromView:nil];
        if (NSMaxX(contentLayoutRect) > 0 && NSMaxY(contentLayoutRect) > 0) {
            contentInsets = NSEdgeInsetsMake(NSHeight(self.bounds) - NSMaxY(contentLayoutRect),
                                             MAX(NSMinX(contentLayoutRect), 0),
                                             MAX(NSMinY(contentLayoutRect), 0),
                                             NSWidth(self.bounds) - NSMaxX(contentLayoutRect));
        }
    } else {
        contentInsets = NSEdgeInsetsZero;
    }

    self.contentInsets = contentInsets;
}

- (void)setContentInsets:(NSEdgeInsets)contentInsets {
    [self setContentInsets:contentInsets animated:NO completionHandler:nil];
}

- (void)setContentInsets:(NSEdgeInsets)contentInsets animated:(BOOL)animated {
    [self setContentInsets:contentInsets animated:animated completionHandler:nil];
}

- (void)setContentInsets:(NSEdgeInsets)contentInsets animated:(BOOL)animated completionHandler:(nullable void (^)(void))completion {
    if (NSEdgeInsetsEqual(contentInsets, self.contentInsets)) {
        if (completion) {
            completion();
        }
        return;
    }
    MHLogDebug(@"Setting contentInset: %@ animated:", MHStringFromNSEdgeInsets(contentInsets), MHStringFromBOOL(animated));
    // After adjusting the content insets, move the center coordinate from the
    // old frame of reference to the new one represented by the newly set
    // content insets.
    CLLocationCoordinate2D oldCenter = self.centerCoordinate;
    _contentInsets = contentInsets;
    [self setCenterCoordinate:oldCenter animated:animated completionHandler:completion];
}

// MARK: Mouse events and gestures

- (BOOL)acceptsFirstResponder {
    return YES;
}

/// Drag to pan, plus drag to zoom, rotate, and tilt when a modifier key is held
/// down.
- (void)handlePanGesture:(NSPanGestureRecognizer *)gestureRecognizer {
    NSPoint delta = [gestureRecognizer translationInView:self];
    NSPoint endPoint = [gestureRecognizer locationInView:self];
    NSPoint startPoint = NSMakePoint(endPoint.x - delta.x, endPoint.y - delta.y);

    NSEventModifierFlags flags = [NSApp currentEvent].modifierFlags;
    if (gestureRecognizer.state == NSGestureRecognizerStateBegan) {
        [self.window invalidateCursorRectsForView:self];
        _mbglMap->setGestureInProgress(true);

        if (![self isPanningWithGesture]) {
            // Hide the cursor except when panning.
            CGDisplayHideCursor(kCGDirectMainDisplay);
            _didHideCursorDuringGesture = YES;
        }
    } else if (gestureRecognizer.state == NSGestureRecognizerStateEnded
               || gestureRecognizer.state == NSGestureRecognizerStateCancelled) {
        _mbglMap->setGestureInProgress(false);
        [self.window invalidateCursorRectsForView:self];

        if (_didHideCursorDuringGesture) {
            _didHideCursorDuringGesture = NO;
            // Move the cursor back to the start point and show it again, creating
            // the illusion that it has stayed in place during the entire gesture.
            CGPoint cursorPoint = [self convertPoint:startPoint toView:nil];
            cursorPoint = [self.window convertRectToScreen:{ cursorPoint, NSZeroSize }].origin;
            cursorPoint.y = self.window.screen.frame.size.height - cursorPoint.y;
            CGDisplayMoveCursorToPoint(kCGDirectMainDisplay, cursorPoint);
            CGDisplayShowCursor(kCGDirectMainDisplay);
        }
    }
    if (flags & NSEventModifierFlagShift) {
        // Shift-drag to zoom.
        if (!self.zoomEnabled) {
            return;
        }

        _mbglMap->cancelTransitions();

        if (gestureRecognizer.state == NSGestureRecognizerStateBegan) {
            _zoomAtBeginningOfGesture = [self zoomLevel];
        } else if (gestureRecognizer.state == NSGestureRecognizerStateChanged) {
            CGFloat newZoomLevel = _zoomAtBeginningOfGesture - delta.y / 75;
            [self setZoomLevel:newZoomLevel atPoint:startPoint animated:NO];
        }
    } else if (flags & NSEventModifierFlagOption) {
        // Option-drag to rotate and/or tilt.
        _mbglMap->cancelTransitions();

        if (gestureRecognizer.state == NSGestureRecognizerStateBegan) {
            _directionAtBeginningOfGesture = self.direction;
            _pitchAtBeginningOfGesture = *_mbglMap->getCameraOptions().pitch;
        } else if (gestureRecognizer.state == NSGestureRecognizerStateChanged) {
            MHMapCamera *oldCamera = self.camera;
            BOOL didChangeCamera = NO;
            mbgl::ScreenCoordinate center(startPoint.x, self.bounds.size.height - startPoint.y);
            if (self.rotateEnabled) {
                CLLocationDirection newDirection = _directionAtBeginningOfGesture - delta.x / 10;
                [self willChangeValueForKey:@"direction"];
                _mbglMap->jumpTo(mbgl::CameraOptions().withBearing(newDirection).withAnchor(center));
                didChangeCamera = YES;
                [self didChangeValueForKey:@"direction"];
            }
            if (self.pitchEnabled) {
                _mbglMap->jumpTo(mbgl::CameraOptions().withPitch(_pitchAtBeginningOfGesture + delta.y / 5).withAnchor(center));
                didChangeCamera = YES;
            }
            
            if (didChangeCamera
                && [self.delegate respondsToSelector:@selector(mapView:shouldChangeFromCamera:toCamera:)]
                && ![self.delegate mapView:self shouldChangeFromCamera:oldCamera toCamera:self.camera]) {
                self.camera = oldCamera;
            }
        }
    } else if (self.scrollEnabled) {
        // Otherwise, drag to pan.
        _mbglMap->cancelTransitions();

        if (gestureRecognizer.state == NSGestureRecognizerStateChanged) {
            delta.y *= -1;
            [self offsetCenterCoordinateBy:delta animated:NO];
            [gestureRecognizer setTranslation:NSZeroPoint inView:nil];
        }
    }
}

/// Returns whether the user is panning using a gesture.
- (BOOL)isPanningWithGesture {
  NSGestureRecognizerState state = _panGestureRecognizer.state;
  NSEventModifierFlags flags = [NSApp currentEvent].modifierFlags;
  return ((state == NSGestureRecognizerStateBegan || state == NSGestureRecognizerStateChanged)
          && !(flags & NSEventModifierFlagShift || flags & NSEventModifierFlagOption));
}

/// Pinch to zoom.
- (void)handleMagnificationGesture:(NSMagnificationGestureRecognizer *)gestureRecognizer {
    if (!self.zoomEnabled) {
        return;
    }

    _mbglMap->cancelTransitions();

    if (gestureRecognizer.state == NSGestureRecognizerStateBegan) {
        _mbglMap->setGestureInProgress(true);
        _zoomAtBeginningOfGesture = [self zoomLevel];
    } else if (gestureRecognizer.state == NSGestureRecognizerStateChanged) {
        NSPoint zoomInPoint = [gestureRecognizer locationInView:self];
        mbgl::ScreenCoordinate center(zoomInPoint.x, self.bounds.size.height - zoomInPoint.y);
        if (gestureRecognizer.magnification > -1) {
            [self willChangeValueForKey:@"zoomLevel"];
            [self willChangeValueForKey:@"centerCoordinate"];
            MHMapCamera *oldCamera = self.camera;
            _mbglMap->jumpTo(mbgl::CameraOptions()
                                 .withZoom(_zoomAtBeginningOfGesture + log2(1 + gestureRecognizer.magnification))
                                 .withAnchor(center));
            if ([self.delegate respondsToSelector:@selector(mapView:shouldChangeFromCamera:toCamera:)]
                && ![self.delegate mapView:self shouldChangeFromCamera:oldCamera toCamera:self.camera]) {
                self.camera = oldCamera;
            }
            [self didChangeValueForKey:@"centerCoordinate"];
            [self didChangeValueForKey:@"zoomLevel"];
        }
    } else if (gestureRecognizer.state == NSGestureRecognizerStateEnded
               || gestureRecognizer.state == NSGestureRecognizerStateCancelled) {
        _mbglMap->setGestureInProgress(false);
    }
}

/// Click or tap to select an annotation.
- (void)handleClickGesture:(NSClickGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != NSGestureRecognizerStateEnded
        || [self subviewContainingGesture:gestureRecognizer]) {
        return;
    }

    NSPoint gesturePoint = [gestureRecognizer locationInView:self];
    MHAnnotationTag hitAnnotationTag = [self annotationTagAtPoint:gesturePoint persistingResults:YES];
    if (hitAnnotationTag != MHAnnotationTagNotFound) {
        if (hitAnnotationTag != _selectedAnnotationTag) {
            id <MHAnnotation> annotation = [self annotationWithTag:hitAnnotationTag];
            NSAssert(annotation, @"Cannot select nonexistent annotation with tag %llu", hitAnnotationTag);
            [self selectAnnotation:annotation atPoint:gesturePoint];
        }
    } else {
        [self deselectAnnotation:self.selectedAnnotation];
    }
}

/// Right-click to show the context menu.
- (void)handleRightClickGesture:(NSClickGestureRecognizer *)gestureRecognizer {
    NSMenu *menu = [self menuForEvent:[NSApp currentEvent]];
    if (menu) {
        [NSMenu popUpContextMenu:menu withEvent:[NSApp currentEvent] forView:self];
    }
}

/// Double-click or double-tap to zoom in.
- (void)handleDoubleClickGesture:(NSClickGestureRecognizer *)gestureRecognizer {
    if (!self.zoomEnabled || gestureRecognizer.state != NSGestureRecognizerStateEnded
        || [self subviewContainingGesture:gestureRecognizer]) {
        return;
    }

    _mbglMap->cancelTransitions();

    NSPoint gesturePoint = [gestureRecognizer locationInView:self];
    [self setZoomLevel:round(self.zoomLevel) + 1 atPoint:gesturePoint animated:YES];
}

- (void)smartMagnifyWithEvent:(NSEvent *)event {
    if (!self.zoomEnabled) {
        return;
    }

    _mbglMap->cancelTransitions();

    // Tap with two fingers (“right-click”) to zoom out on mice but not trackpads.
    NSPoint gesturePoint = [self convertPoint:event.locationInWindow fromView:nil];
    [self setZoomLevel:round(self.zoomLevel) - 1 atPoint:gesturePoint animated:YES];
}

/// Rotate fingers to rotate.
- (void)handleRotationGesture:(NSRotationGestureRecognizer *)gestureRecognizer {
    if (!self.rotateEnabled) {
        return;
    }

    _mbglMap->cancelTransitions();

    if (gestureRecognizer.state == NSGestureRecognizerStateBegan) {
        _mbglMap->setGestureInProgress(true);
        _directionAtBeginningOfGesture = self.direction;
    } else if (gestureRecognizer.state == NSGestureRecognizerStateChanged) {
        MHMapCamera *oldCamera = self.camera;
        
        NSPoint rotationPoint = [gestureRecognizer locationInView:self];
        mbgl::ScreenCoordinate anchor(rotationPoint.x, self.bounds.size.height - rotationPoint.y);
        _mbglMap->jumpTo(mbgl::CameraOptions()
                             .withBearing(_directionAtBeginningOfGesture + gestureRecognizer.rotationInDegrees)
                             .withAnchor(anchor));
        
        if ([self.delegate respondsToSelector:@selector(mapView:shouldChangeFromCamera:toCamera:)]
            && ![self.delegate mapView:self shouldChangeFromCamera:oldCamera toCamera:self.camera]) {
            self.camera = oldCamera;
        }
    } else if (gestureRecognizer.state == NSGestureRecognizerStateEnded
               || gestureRecognizer.state == NSGestureRecognizerStateCancelled) {
        _mbglMap->setGestureInProgress(false);
    }
}

- (BOOL)wantsScrollEventsForSwipeTrackingOnAxis:(__unused NSEventGestureAxis)axis {
    // Track both horizontal and vertical swipes in -scrollWheel:.
    return YES;
}

- (void)scrollWheel:(NSEvent *)event {
    // https://developer.apple.com/library/mac/releasenotes/AppKit/RN-AppKitOlderNotes/#10_7Dragging
    BOOL isScrollWheel = event.phase == NSEventPhaseNone && event.momentumPhase == NSEventPhaseNone && !event.hasPreciseScrollingDeltas;
    if (isScrollWheel || [[NSUserDefaults standardUserDefaults] boolForKey:MHScrollWheelZoomsMapViewDefaultKey]) {
        // A traditional, vertical scroll wheel zooms instead of panning.
        if (self.zoomEnabled) {
            const double delta =
                event.scrollingDeltaY / ([event hasPreciseScrollingDeltas] ? 100 : 10);
            if (delta != 0) {
                double scale = 2.0 / (1.0 + std::exp(-std::abs(delta)));

                // Zooming out.
                if (delta < 0) {
                    scale = 1.0 / scale;
                }

                NSPoint gesturePoint = [self convertPoint:event.locationInWindow fromView:nil];
                [self setZoomLevel:self.zoomLevel + log2(scale) atPoint:gesturePoint animated:NO];
            }
        }
    } else if (self.scrollEnabled
               && _magnificationGestureRecognizer.state == NSGestureRecognizerStatePossible
               && _rotationGestureRecognizer.state == NSGestureRecognizerStatePossible) {
        // Scroll to pan.
        _mbglMap->cancelTransitions();

        CGFloat x = event.scrollingDeltaX;
        CGFloat y = event.scrollingDeltaY;
        if (x || y) {
            [self offsetCenterCoordinateBy:NSMakePoint(x, y) animated:NO];
        }

        // Drift pan.
        if (event.momentumPhase != NSEventPhaseNone) {
            [self offsetCenterCoordinateBy:NSMakePoint(x, y) animated:NO];
        }
    }
}

/// Returns the subview that the gesture is located in.
- (NSView *)subviewContainingGesture:(NSGestureRecognizer *)gestureRecognizer {
    if (NSPointInRect([gestureRecognizer locationInView:self.compass], self.compass.bounds)) {
        return self.compass;
    }
    if (NSPointInRect([gestureRecognizer locationInView:self.zoomControls], self.zoomControls.bounds)) {
        return self.zoomControls;
    }
    if (NSPointInRect([gestureRecognizer locationInView:self.attributionView], self.attributionView.bounds)) {
        return self.attributionView;
    }
    return nil;
}

// MARK: NSGestureRecognizerDelegate methods
- (BOOL)gestureRecognizer:(NSGestureRecognizer *)gestureRecognizer shouldAttemptToRecognizeWithEvent:(NSEvent *)event {
    if (gestureRecognizer == _singleClickRecognizer) {
        if (!self.selectedAnnotation) {
            NSPoint gesturePoint = [self convertPoint:[event locationInWindow] fromView:nil];
            MHAnnotationTag hitAnnotationTag = [self annotationTagAtPoint:gesturePoint persistingResults:NO];
            if (hitAnnotationTag == MHAnnotationTagNotFound) {
                return NO;
            }
        }
    }
    return YES;
}

// MARK: Keyboard events

- (void)keyDown:(NSEvent *)event {
    // This is the recommended way to handle arrow key presses, causing
    // methods like -moveUp: and -moveToBeginningOfParagraph: to be called
    // for various standard keybindings.
    [self interpretKeyEvents:@[event]];
}

// The following action methods are declared in NSResponder.h.

- (void)insertTab:(id)sender {
    if (self.window.firstResponder == self) {
        [self.window selectNextKeyView:self];
    }
}

- (void)insertBacktab:(id)sender {
    if (self.window.firstResponder == self) {
        [self.window selectPreviousKeyView:self];
    }
}

- (void)insertText:(NSString *)insertString {
    switch (insertString.length == 1 ? [insertString characterAtIndex:0] : 0) {
        case '-':
            [self moveToEndOfParagraph:nil];
            break;
            
        case '+':
        case '=':
            [self moveToBeginningOfParagraph:nil];
            break;
            
        default:
            [super insertText:insertString];
            break;
    }
}

- (IBAction)moveUp:(__unused id)sender {
    [self offsetCenterCoordinateBy:NSMakePoint(0, MHKeyPanningIncrement) animated:YES];
}

- (IBAction)moveDown:(__unused id)sender {
    [self offsetCenterCoordinateBy:NSMakePoint(0, -MHKeyPanningIncrement) animated:YES];
}

- (IBAction)moveLeft:(__unused id)sender {
    [self offsetCenterCoordinateBy:NSMakePoint(MHKeyPanningIncrement, 0) animated:YES];
}

- (IBAction)moveRight:(__unused id)sender {
    [self offsetCenterCoordinateBy:NSMakePoint(-MHKeyPanningIncrement, 0) animated:YES];
}

- (IBAction)moveToBeginningOfParagraph:(__unused id)sender {
    if (self.zoomEnabled) {
        [self setZoomLevel:round(self.zoomLevel) + 1 animated:YES];
    }
}

- (IBAction)moveToEndOfParagraph:(__unused id)sender {
    if (self.zoomEnabled) {
        [self setZoomLevel:round(self.zoomLevel) - 1 animated:YES];
    }
}

- (IBAction)moveWordLeft:(__unused id)sender {
    if (self.rotateEnabled) {
        [self offsetDirectionBy:MHKeyRotationIncrement animated:YES];
    }
}

- (IBAction)moveWordRight:(__unused id)sender {
    if (self.rotateEnabled) {
        [self offsetDirectionBy:-MHKeyRotationIncrement animated:YES];
    }
}

- (void)setZoomEnabled:(BOOL)zoomEnabled {
    _zoomEnabled = zoomEnabled;
    _zoomControls.enabled = zoomEnabled;
    _zoomControls.hidden = !zoomEnabled;
}

- (void)setRotateEnabled:(BOOL)rotateEnabled {
    _rotateEnabled = rotateEnabled;
    _compass.enabled = rotateEnabled;
    _compass.hidden = !rotateEnabled;
}

// MARK: Ornaments

/// Updates the zoom controls’ enabled state based on the current zoom level.
- (void)updateZoomControls {
    [_zoomControls setEnabled:self.zoomLevel > self.minimumZoomLevel forSegment:0];
    [_zoomControls setEnabled:self.zoomLevel < self.maximumZoomLevel forSegment:1];
}

/// Updates the compass to point in the same direction as the map.
- (void)updateCompass {
    // The circular slider control goes counterclockwise, whereas our map
    // measures its direction clockwise.
    _compass.doubleValue = -self.direction;
}

- (IBAction)rotate:(NSSlider *)sender {
    [self setDirection:-sender.doubleValue animated:YES];
}

// MARK: Annotations

- (nullable NSArray<id <MHAnnotation>> *)annotations {
    if (_annotationContextsByAnnotationTag.empty()) {
        return nil;
    }

    // Map all the annotation tags to the annotations themselves.
    std::vector<id <MHAnnotation>> annotations;
    std::transform(_annotationContextsByAnnotationTag.begin(),
                   _annotationContextsByAnnotationTag.end(),
                   std::back_inserter(annotations),
                   ^ id <MHAnnotation> (const std::pair<MHAnnotationTag, MHAnnotationContext> &pair) {
                       return pair.second.annotation;
                   });
    return [NSArray arrayWithObjects:&annotations[0] count:annotations.size()];
}

- (nullable NSArray<id <MHAnnotation>> *)visibleAnnotations
{
    return [self visibleAnnotationsInRect:self.bounds];
}

- (nullable NSArray<id <MHAnnotation>> *)visibleAnnotationsInRect:(CGRect)rect
{
    if (_annotationContextsByAnnotationTag.empty())
    {
        return nil;
    }

    std::vector<MHAnnotationTag> annotationTags = [self annotationTagsInRect:rect];
    std::vector<MHAnnotationTag> shapeAnnotationTags = [self shapeAnnotationTagsInRect:rect];
    
    if (shapeAnnotationTags.size()) {
        annotationTags.insert(annotationTags.end(), shapeAnnotationTags.begin(), shapeAnnotationTags.end());
    }
    
    if (annotationTags.size())
    {
        NSMutableArray *annotations = [NSMutableArray arrayWithCapacity:annotationTags.size()];

        for (auto const& annotationTag: annotationTags)
        {
            if (!_annotationContextsByAnnotationTag.count(annotationTag) ||
                annotationTag == MHAnnotationTagNotFound)
            {
                continue;
            }

            MHAnnotationContext annotationContext = _annotationContextsByAnnotationTag.at(annotationTag);
            NSAssert(annotationContext.annotation, @"Missing annotation for tag %llu.", annotationTag);
            if (annotationContext.annotation)
            {
                [annotations addObject:annotationContext.annotation];
            }
        }

        return [annotations copy];
    }

    return nil;
}

/// Returns the annotation assigned the given tag. Cheap.
- (id <MHAnnotation>)annotationWithTag:(MHAnnotationTag)tag {
    if ( ! _annotationContextsByAnnotationTag.count(tag) ||
        tag == MHAnnotationTagNotFound) {
        return nil;
    }

    MHAnnotationContext &annotationContext = _annotationContextsByAnnotationTag.at(tag);
    return annotationContext.annotation;
}

/// Returns the annotation tag assigned to the given annotation.
- (MHAnnotationTag)annotationTagForAnnotation:(id <MHAnnotation>)annotation {
    if (!annotation || _annotationTagsByAnnotation.count(annotation) == 0) {
        return MHAnnotationTagNotFound;
    }

    return  _annotationTagsByAnnotation.at(annotation);
}

- (void)addAnnotation:(id <MHAnnotation>)annotation {
    if (annotation) {
        [self addAnnotations:@[annotation]];
    }
}

- (void)addAnnotations:(NSArray<id <MHAnnotation>> *)annotations {
    if (!annotations) {
        return;
    }

    [self willChangeValueForKey:@"annotations"];

    BOOL delegateHasImagesForAnnotations = [self.delegate respondsToSelector:@selector(mapView:imageForAnnotation:)];

    for (id <MHAnnotation> annotation in annotations) {
        NSAssert([annotation conformsToProtocol:@protocol(MHAnnotation)], @"Annotation does not conform to MHAnnotation");

        // adding the same annotation object twice is a no-op
        if (_annotationTagsByAnnotation.count(annotation) != 0) {
            continue;
        }

        if ([annotation isKindOfClass:[MHMultiPoint class]]) {
            // The multipoint knows how to style itself (with the map view’s help).
            MHMultiPoint *multiPoint = (MHMultiPoint *)annotation;
            if (!multiPoint.pointCount) {
                continue;
            }

            _isChangingAnnotationLayers = YES;
            MHAnnotationTag annotationTag = _mbglMap->addAnnotation([multiPoint annotationObjectWithDelegate:self]);
            MHAnnotationContext context;
            context.annotation = annotation;
            _annotationContextsByAnnotationTag[annotationTag] = context;
            _annotationTagsByAnnotation[annotation] = annotationTag;

            [(NSObject *)annotation addObserver:self forKeyPath:@"coordinates" options:0 context:(void *)(NSUInteger)annotationTag];
        } else if (![annotation isKindOfClass:[MHMultiPolyline class]]
                   && ![annotation isKindOfClass:[MHMultiPolygon class]]
                   && ![annotation isKindOfClass:[MHShapeCollection class]]
                   && ![annotation isKindOfClass:[MHPointCollection class]]) {
            MHAnnotationImage *annotationImage = nil;
            if (delegateHasImagesForAnnotations) {
                annotationImage = [self.delegate mapView:self imageForAnnotation:annotation];
            }
            if (!annotationImage) {
                annotationImage = [self dequeueReusableAnnotationImageWithIdentifier:MHDefaultStyleMarkerSymbolName];
            }
            if (!annotationImage) {
                annotationImage = self.defaultAnnotationImage;
            }

            NSString *symbolName = annotationImage.styleIconIdentifier;
            if (!symbolName) {
                symbolName = [MHAnnotationSpritePrefix stringByAppendingString:annotationImage.reuseIdentifier];
                annotationImage.styleIconIdentifier = symbolName;
            }

            if (!self.annotationImagesByIdentifier[annotationImage.reuseIdentifier]) {
                self.annotationImagesByIdentifier[annotationImage.reuseIdentifier] = annotationImage;
                [self installAnnotationImage:annotationImage];
            }

            MHAnnotationTag annotationTag = _mbglMap->addAnnotation(mbgl::SymbolAnnotation {
                MHPointFeatureClusterFromLocationCoordinate2D(annotation.coordinate),
                symbolName.UTF8String ?: ""
            });

            MHAnnotationContext context;
            context.annotation = annotation;
            context.imageReuseIdentifier = annotationImage.reuseIdentifier;
            _annotationContextsByAnnotationTag[annotationTag] = context;
            _annotationTagsByAnnotation[annotation] = annotationTag;

            if ([annotation isKindOfClass:[NSObject class]]) {
                NSAssert(![annotation isKindOfClass:[MHMultiPoint class]], @"Point annotation should not be MHMultiPoint.");
                [(NSObject *)annotation addObserver:self forKeyPath:@"coordinate" options:0 context:(void *)(NSUInteger)annotationTag];
            }

            // Opt into potentially expensive tooltip tracking areas.
            if ([annotation respondsToSelector:@selector(toolTip)] && annotation.toolTip.length) {
                _wantsToolTipRects = YES;
            }
        }
    }

    [self didChangeValueForKey:@"annotations"];
    if (_isChangingAnnotationLayers) {
        [self.style willChangeValueForKey:@"layers"];
    }

    [self updateAnnotationTrackingAreas];
}

/// Initializes and returns a default annotation image that depicts a round pin
/// rising from the center, with a shadow slightly below center. The alignment
/// rect therefore excludes the bottom half.
- (MHAnnotationImage *)defaultAnnotationImage {
    NSImage *image = MHDefaultMarkerImage();
    NSRect alignmentRect = image.alignmentRect;
    alignmentRect.origin.y = NSMidY(alignmentRect);
    alignmentRect.size.height /= 2;
    image.alignmentRect = alignmentRect;
    return [MHAnnotationImage annotationImageWithImage:image
                                        reuseIdentifier:MHDefaultStyleMarkerSymbolName];
}

/// Sends the raw pixel data of the annotation image’s image to mbgl and
/// calculates state needed for hit testing later.
- (void)installAnnotationImage:(MHAnnotationImage *)annotationImage {
    NSString *iconIdentifier = annotationImage.styleIconIdentifier;
    self.annotationImagesByIdentifier[annotationImage.reuseIdentifier] = annotationImage;

    NSImage *image = annotationImage.image;
    NSSize size = image.size;
    if (size.width == 0 || size.height == 0 || !image.valid) {
        // Can’t create an empty sprite. An image that hasn’t loaded is also useless.
        return;
    }

    _mbglMap->addAnnotationImage([annotationImage.image mgl_styleImageWithIdentifier:iconIdentifier]);

    // Create a slop area with a “radius” equal to the annotation image’s entire
    // size, allowing the eventual click to be on any point within this image.
    // Union this slop area with any existing slop areas.
    _unionedAnnotationImageSize = NSMakeSize(MAX(_unionedAnnotationImageSize.width, size.width),
                                             MAX(_unionedAnnotationImageSize.height, size.height));

    // Opt into potentially expensive cursor tracking areas.
    if (annotationImage.cursor) {
        _wantsCursorRects = YES;
    }
}

- (void)removeAnnotation:(id <MHAnnotation>)annotation {
    if (annotation) {
        [self removeAnnotations:@[annotation]];
    }
}

- (void)removeAnnotations:(NSArray<id <MHAnnotation>> *)annotations {
    if (!annotations) {
        return;
    }

    [self willChangeValueForKey:@"annotations"];

    for (id <MHAnnotation> annotation in annotations) {
        NSAssert([annotation conformsToProtocol:@protocol(MHAnnotation)], @"Annotation does not conform to MHAnnotation");

        MHAnnotationTag annotationTag = [self annotationTagForAnnotation:annotation];
        NSAssert(annotationTag != MHAnnotationTagNotFound, @"No ID for annotation %@", annotation);

        if (annotationTag == _selectedAnnotationTag) {
            [self deselectAnnotation:annotation];
        }
        if (annotationTag == _lastSelectedAnnotationTag) {
            _lastSelectedAnnotationTag = MHAnnotationTagNotFound;
        }

        _annotationContextsByAnnotationTag.erase(annotationTag);
        _annotationTagsByAnnotation.erase(annotation);

        if ([annotation isKindOfClass:[NSObject class]] &&
            ![annotation isKindOfClass:[MHMultiPoint class]]) {
            [(NSObject *)annotation removeObserver:self forKeyPath:@"coordinate" context:(void *)(NSUInteger)annotationTag];
        } else if ([annotation isKindOfClass:[MHMultiPoint class]]) {
            [(NSObject *)annotation removeObserver:self forKeyPath:@"coordinates" context:(void *)(NSUInteger)annotationTag];
        }

        _isChangingAnnotationLayers = YES;
        _mbglMap->removeAnnotation(annotationTag);
    }

    [self didChangeValueForKey:@"annotations"];
    if (_isChangingAnnotationLayers) {
        [self.style willChangeValueForKey:@"layers"];
    }

    [self updateAnnotationTrackingAreas];
}

- (nullable MHAnnotationImage *)dequeueReusableAnnotationImageWithIdentifier:(NSString *)identifier {
    return self.annotationImagesByIdentifier[identifier];
}

- (id <MHAnnotation>)annotationAtPoint:(NSPoint)point {
    return [self annotationWithTag:[self annotationTagAtPoint:point persistingResults:NO]];
}

/**
    Returns the tag of the annotation at the given point in the view.

    This is more involved than it sounds: if multiple point annotations overlap
    near the point, this method cycles through them so that each of them is
    accessible to the user at some point.

    @param persist True to remember the cycleable set of annotations, so that a
        different annotation is returned the next time this method is called
        with the same point. Setting this parameter to false is useful for
        asking “what if?”
 */
- (MHAnnotationTag)annotationTagAtPoint:(NSPoint)point persistingResults:(BOOL)persist {
    // Look for any annotation near the click. An annotation is “near” if the
    // distance between its center and the click is less than the maximum height
    // or width of an installed annotation image.
    NSRect queryRect = NSInsetRect({ point, NSZeroSize },
                                   -_unionedAnnotationImageSize.width / 2,
                                   -_unionedAnnotationImageSize.height / 2);
    queryRect = NSInsetRect(queryRect, -MHAnnotationImagePaddingForHitTest,
                            -MHAnnotationImagePaddingForHitTest);
    std::vector<MHAnnotationTag> nearbyAnnotations = [self annotationTagsInRect:queryRect];
    std::vector<MHAnnotationTag> nearbyShapeAnnotations = [self shapeAnnotationTagsInRect:queryRect];
    
    if (nearbyShapeAnnotations.size()) {
        nearbyAnnotations.insert(nearbyAnnotations.end(), nearbyShapeAnnotations.begin(), nearbyShapeAnnotations.end());
    }

    if (nearbyAnnotations.size()) {
        // Assume that the user is fat-fingering an annotation.
        NSRect hitRect = NSInsetRect({ point, NSZeroSize },
                                     -MHAnnotationImagePaddingForHitTest,
                                     -MHAnnotationImagePaddingForHitTest);
        
        // Filter out any annotation whose image is unselectable or for which
        // hit testing fails.
        auto end = std::remove_if(nearbyAnnotations.begin(), nearbyAnnotations.end(), [&](const MHAnnotationTag annotationTag) {
            id <MHAnnotation> annotation = [self annotationWithTag:annotationTag];
            NSAssert(annotation, @"Unknown annotation found nearby click");
            if (!annotation) {
                return true;
            }
            
            if ([annotation isKindOfClass:[MHMultiPoint class]])
            {
                if ([self.delegate respondsToSelector:@selector(mapView:shapeAnnotationIsEnabled:)]) {
                    return !!(![self.delegate mapView:self shapeAnnotationIsEnabled:(MHMultiPoint *)annotation]);
                } else {
                    return false;
                }
            }
            
            MHAnnotationImage *annotationImage = [self imageOfAnnotationWithTag:annotationTag];
            if (!annotationImage.selectable) {
                return true;
            }
            
            // Filter out the annotation if the fattened finger didn’t land on a
            // translucent or opaque pixel in the image.
            NSRect annotationRect = [self frameOfImage:annotationImage.image
                                  centeredAtCoordinate:annotation.coordinate];
            return !!![annotationImage.image hitTestRect:hitRect withImageDestinationRect:annotationRect
                                                 context:nil hints:nil flipped:NO];
        });
        nearbyAnnotations.resize(std::distance(nearbyAnnotations.begin(), end));
    }

    MHAnnotationTag hitAnnotationTag = MHAnnotationTagNotFound;
    if (nearbyAnnotations.size()) {
        // The first selection in the cycle should be the one nearest to the
        // tap. Also the annotation tags need to be stable in order to compare them with
        // the remembered tags _annotationsNearbyLastClick.
        CLLocationCoordinate2D currentCoordinate = [self convertPoint:point toCoordinateFromView:self];
        std::sort(nearbyAnnotations.begin(), nearbyAnnotations.end(), [&](const MHAnnotationTag tagA, const MHAnnotationTag tagB) {
            CLLocationCoordinate2D coordinateA = [[self annotationWithTag:tagA] coordinate];
            CLLocationCoordinate2D coordinateB = [[self annotationWithTag:tagB] coordinate];
            CLLocationDegrees deltaA = hypot(coordinateA.latitude - currentCoordinate.latitude,
                                             coordinateA.longitude - currentCoordinate.longitude);
            CLLocationDegrees deltaB = hypot(coordinateB.latitude - currentCoordinate.latitude,
                                             coordinateB.longitude - currentCoordinate.longitude);
            return deltaA < deltaB;
        });
        
        if (nearbyAnnotations == _annotationsNearbyLastClick) {
            // The last time we persisted a set of annotations, we had the same
            // set of annotations as we do now. Cycle through them.
            if (_lastSelectedAnnotationTag == MHAnnotationTagNotFound
                || _lastSelectedAnnotationTag == nearbyAnnotations.back()) {
                // Either no annotation is selected or the last annotation in
                // the set was selected. Wrap around to the first annotation in
                // the set.
                hitAnnotationTag = nearbyAnnotations.front();
            } else {
                auto result = std::find(nearbyAnnotations.begin(),
                                        nearbyAnnotations.end(),
                                        _lastSelectedAnnotationTag);
                if (result == nearbyAnnotations.end()) {
                    // An annotation from this set hasn’t been selected before.
                    // Select the first (nearest) one.
                    hitAnnotationTag = nearbyAnnotations.front();
                } else {
                    // Step to the next annotation in the set.
                    auto distance = std::distance(nearbyAnnotations.begin(), result);
                    hitAnnotationTag = nearbyAnnotations[distance + 1];
                }
            }
        } else {
            // Remember the nearby annotations for the next time this method is
            // called.
            if (persist) {
                _annotationsNearbyLastClick = nearbyAnnotations;
            }

            // Choose the first nearby annotation.
            if (nearbyAnnotations.size()) {
                hitAnnotationTag = nearbyAnnotations.front();
            }
        }
    }

    return hitAnnotationTag;
}

/// Returns the tags of the annotations coincident with the given rectangle.
- (std::vector<MHAnnotationTag>)annotationTagsInRect:(NSRect)rect {
    // Cocoa origin is at the lower-left corner.
    return self.renderer->queryPointAnnotations({
        { NSMinX(rect), NSHeight(self.bounds) - NSMaxY(rect) },
        { NSMaxX(rect), NSHeight(self.bounds) - NSMinY(rect) },
    });
}

- (std::vector<MHAnnotationTag>)shapeAnnotationTagsInRect:(NSRect)rect {
    // Cocoa origin is at the lower-left corner.
    return _rendererFrontend->getRenderer()->queryShapeAnnotations({
        { NSMinX(rect), NSHeight(self.bounds) - NSMaxY(rect) },
        { NSMaxX(rect), NSHeight(self.bounds) - NSMinY(rect) },
    });
}

- (id <MHAnnotation>)selectedAnnotation {
    if ( ! _annotationContextsByAnnotationTag.count(_selectedAnnotationTag) ||
        _selectedAnnotationTag == MHAnnotationTagNotFound) {
        return nil;
    }
    
    MHAnnotationContext &annotationContext = _annotationContextsByAnnotationTag.at(_selectedAnnotationTag);
    return annotationContext.annotation;
}

- (void)setSelectedAnnotation:(id <MHAnnotation>)annotation {
    MHLogDebug(@"Selecting annotation: %@", annotation);
    [self willChangeValueForKey:@"selectedAnnotations"];
    _selectedAnnotationTag = [self annotationTagForAnnotation:annotation];
    if (_selectedAnnotationTag != MHAnnotationTagNotFound) {
        _lastSelectedAnnotationTag = _selectedAnnotationTag;
    }
    [self didChangeValueForKey:@"selectedAnnotations"];
}

- (NSArray<id <MHAnnotation>> *)selectedAnnotations {
    id <MHAnnotation> selectedAnnotation = self.selectedAnnotation;
    return selectedAnnotation ? @[selectedAnnotation] : @[];
}

- (void)setSelectedAnnotations:(NSArray<id <MHAnnotation>> *)selectedAnnotations {
    MHLogDebug(@"Selecting: %lu annotations", selectedAnnotations.count);
    if (!selectedAnnotations.count) {
        return;
    }

    id <MHAnnotation> firstAnnotation = selectedAnnotations[0];
    NSAssert([firstAnnotation conformsToProtocol:@protocol(MHAnnotation)], @"Annotation does not conform to MHAnnotation");
    if ([firstAnnotation isKindOfClass:[MHMultiPoint class]]) {
        return;
    }

    [self selectAnnotation:firstAnnotation];
}

- (BOOL)isMovingAnnotationIntoViewSupportedForAnnotation:(id<MHAnnotation>)annotation animated:(BOOL)animated {
    // Consider delegating
    return [annotation isKindOfClass:[MHPointAnnotation class]];
}

- (void)selectAnnotation:(id <MHAnnotation>)annotation
{
    MHLogDebug(@"Selecting annotation: %@", annotation);
    [self selectAnnotation:annotation atPoint:NSZeroPoint];
}

- (void)selectAnnotation:(id <MHAnnotation>)annotation atPoint:(NSPoint)gesturePoint
{
    MHLogDebug(@"Selecting annotation: %@ atPoint: %@", annotation, NSStringFromPoint(gesturePoint));
    [self selectAnnotation:annotation atPoint:gesturePoint moveIntoView:YES animateSelection:YES];
}

- (void)selectAnnotation:(id <MHAnnotation>)annotation atPoint:(NSPoint)gesturePoint moveIntoView:(BOOL)moveIntoView animateSelection:(BOOL)animateSelection
{
    MHLogDebug(@"Selecting annotation: %@ atPoint: %@ moveIntoView: %@ animateSelection: %@", annotation, NSStringFromPoint(gesturePoint), MHStringFromBOOL(moveIntoView), MHStringFromBOOL(animateSelection));
    id <MHAnnotation> selectedAnnotation = self.selectedAnnotation;
    if (annotation == selectedAnnotation) {
        return;
    }

    // Deselect the annotation before reselecting it.
    [self deselectAnnotation:selectedAnnotation];

    // Add the annotation to the map if it hasn’t been added yet.
    MHAnnotationTag annotationTag = [self annotationTagForAnnotation:annotation];
    if (annotationTag == MHAnnotationTagNotFound) {
        [self addAnnotation:annotation];
    }

    if (moveIntoView) {
        moveIntoView = [self isMovingAnnotationIntoViewSupportedForAnnotation:annotation animated:animateSelection];
    }

    // The annotation's anchor will bounce to the current click.
    NSRect positioningRect = [self positioningRectForCalloutForAnnotationWithTag:annotationTag];

    // Check for invalid (zero) positioning rect
    if (NSEqualRects(positioningRect, NSZeroRect)) {
        CLLocationCoordinate2D origin = annotation.coordinate;
        positioningRect.origin = [self convertCoordinate:origin toPointToView:self];
    }

    BOOL shouldShowCallout = ([annotation respondsToSelector:@selector(title)]
                              && annotation.title
                              && !self.calloutForSelectedAnnotation.shown
                              && [self.delegate respondsToSelector:@selector(mapView:annotationCanShowCallout:)]
                              && [self.delegate mapView:self annotationCanShowCallout:annotation]);
    
    if (NSIsEmptyRect(NSIntersectionRect(positioningRect, self.bounds))) {
        if (!moveIntoView && !NSEqualPoints(gesturePoint, NSZeroPoint)) {
            positioningRect = CGRectMake(gesturePoint.x, gesturePoint.y, positioningRect.size.width, positioningRect.size.height);
        }
    }
    // Onscreen or partially on-screen
    else if (!shouldShowCallout) {
        moveIntoView = NO;
    }

    self.selectedAnnotation = annotation;

    // For the callout to be shown, the annotation must have a title, its
    // callout must not already be shown, and the annotation must be able to
    // show a callout according to the delegate.
    if (shouldShowCallout) {
        NSPopover *callout = [self calloutForAnnotation:annotation];

        // Hang the callout off the right edge of the annotation image’s
        // alignment rect, or off the left edge in a right-to-left UI.
        callout.delegate = self;
        self.calloutForSelectedAnnotation = callout;

        NSRectEdge edge = (self.userInterfaceLayoutDirection == NSUserInterfaceLayoutDirectionRightToLeft
                           ? NSMinXEdge
                           : NSMaxXEdge);

        // The following will do nothing if the positioning rect is not on-screen. See
        // ``MHMapView/updateAnnotationCallouts`` for presenting the callout when the selected
        // annotation comes back on-screen.
        [callout showRelativeToRect:positioningRect ofView:self preferredEdge:edge];
    }

    if (moveIntoView)
    {
        moveIntoView = NO;

        NSRect (^edgeInsetsInsetRect)(NSRect, NSEdgeInsets) = ^(NSRect rect, NSEdgeInsets insets) {
            return NSMakeRect(rect.origin.x + insets.left,
                              rect.origin.y + insets.bottom,
                              rect.size.width - insets.left - insets.right,
                              rect.size.height - insets.top - insets.bottom);
        };

        // Add padding around the positioning rect (in essence an inset from the edge of the viewport
        NSRect expandedPositioningRect = positioningRect;
        
        if (shouldShowCallout) {
            // If we have a callout, expand this rect to include a buffer
            expandedPositioningRect = edgeInsetsInsetRect(positioningRect, MHMapViewOffscreenAnnotationPadding);
        }

        // Used for callout positioning, and moving offscreen annotations onscreen.
        CGRect constrainedRect = edgeInsetsInsetRect(self.bounds, self.contentInsets);
        CGRect bounds          = constrainedRect;

        // Any one of these cases should trigger a move onscreen
        CGFloat minX = CGRectGetMinX(expandedPositioningRect);
        
        if (minX < CGRectGetMinX(bounds)) {
            constrainedRect.origin.x = minX;
            moveIntoView = YES;
        }
        else {
            CGFloat maxX = CGRectGetMaxX(expandedPositioningRect);
            
            if (maxX > CGRectGetMaxX(bounds)) {
                constrainedRect.origin.x = maxX - CGRectGetWidth(constrainedRect);
                moveIntoView = YES;
            }
        }
        
        CGFloat minY = CGRectGetMinY(expandedPositioningRect);
        
        if (minY < CGRectGetMinY(bounds)) {
            constrainedRect.origin.y = minY;
            moveIntoView = YES;
        }
        else {
            CGFloat maxY = CGRectGetMaxY(expandedPositioningRect);
            
            if (maxY > CGRectGetMaxY(bounds)) {
                constrainedRect.origin.y = maxY - CGRectGetHeight(constrainedRect);
                moveIntoView = YES;
            }
        }

        if (moveIntoView)
        {
            CGPoint center = CGPointMake(CGRectGetMidX(constrainedRect), CGRectGetMidY(constrainedRect));
            CLLocationCoordinate2D centerCoord = [self convertPoint:center toCoordinateFromView:self];
            [self setCenterCoordinate:centerCoord animated:animateSelection];
        }
    }
}

- (void)showAnnotations:(NSArray<id <MHAnnotation>> *)annotations animated:(BOOL)animated {
    MHLogDebug(@"Showing: %lu annotations animated: %@", annotations.count, MHStringFromBOOL(animated));
    CGFloat maximumPadding = 100;
    CGFloat yPadding = (NSHeight(self.bounds) / 5 <= maximumPadding) ? (NSHeight(self.bounds) / 5) : maximumPadding;
    CGFloat xPadding = (NSWidth(self.bounds) / 5 <= maximumPadding) ? (NSWidth(self.bounds) / 5) : maximumPadding;

    NSEdgeInsets edgeInsets = NSEdgeInsetsMake(yPadding, xPadding, yPadding, xPadding);

    [self showAnnotations:annotations edgePadding:edgeInsets animated:animated];
}

- (void)showAnnotations:(NSArray<id <MHAnnotation>> *)annotations edgePadding:(NSEdgeInsets)insets animated:(BOOL)animated {
    [self showAnnotations:annotations edgePadding:insets animated:animated completionHandler:nil];
}

- (void)showAnnotations:(NSArray<id <MHAnnotation>> *)annotations edgePadding:(NSEdgeInsets)insets animated:(BOOL)animated completionHandler:(nullable void (^)(void))completion {
    if (!annotations.count) {
        if (completion) {
            completion();
        }
        return;
    }

    mbgl::LatLngBounds bounds = mbgl::LatLngBounds::empty();

    for (id <MHAnnotation> annotation in annotations) {
        if ([annotation conformsToProtocol:@protocol(MHOverlay)]) {
            bounds.extend(MHLatLngBoundsFromCoordinateBounds(((id <MHOverlay>)annotation).overlayBounds));
        } else {
            bounds.extend(MHLatLngFromLocationCoordinate2D(annotation.coordinate));
        }
    }

    [self setVisibleCoordinateBounds:MHCoordinateBoundsFromLatLngBounds(bounds)
                         edgePadding:insets
                            animated:animated
                   completionHandler:completion];
}

/// Returns a popover detailing the annotation.
- (NSPopover *)calloutForAnnotation:(id <MHAnnotation>)annotation {
    NSPopover *callout = [[NSPopover alloc] init];
    callout.behavior = NSPopoverBehaviorTransient;

    NSViewController *viewController;
    if ([self.delegate respondsToSelector:@selector(mapView:calloutViewControllerForAnnotation:)]) {
        NSViewController *viewControllerFromDelegate = [self.delegate mapView:self
                                           calloutViewControllerForAnnotation:annotation];
        if (viewControllerFromDelegate) {
            viewController = viewControllerFromDelegate;
        }
    }
    if (!viewController) {
        viewController = self.calloutViewController;
    }
    NSAssert(viewController, @"Unable to load MHAnnotationCallout view controller");
    // The popover’s view controller can bind to KVO-compliant key paths of the
    // annotation.
    viewController.representedObject = annotation;
    callout.contentViewController = viewController;

    return callout;
}

- (NSViewController *)calloutViewController {
    // Lazily load a default view controller.
    if (!_calloutViewController) {
        _calloutViewController = [[NSViewController alloc] initWithNibName:@"MHAnnotationCallout"
                                                                    bundle:[NSBundle mgl_frameworkBundle]];
    }
    return _calloutViewController;
}

/// Returns the rectangle that represents the annotation image of the annotation
/// with the given tag. This rectangle is fitted to the image’s alignment rect
/// and is appropriate for positioning a popover.
- (NSRect)positioningRectForCalloutForAnnotationWithTag:(MHAnnotationTag)annotationTag {
    id <MHAnnotation> annotation = [self annotationWithTag:annotationTag];
    if (!annotation) {
        return NSZeroRect;
    }
    if ([annotation isKindOfClass:[MHMultiPoint class]]) {
        CLLocationCoordinate2D origin = annotation.coordinate;
        CGPoint originPoint = [self convertCoordinate:origin toPointToView:self];
        return CGRectMake(originPoint.x, originPoint.y, MHAnnotationImagePaddingForHitTest, MHAnnotationImagePaddingForHitTest);
        
    }
    
    NSImage *image = [self imageOfAnnotationWithTag:annotationTag].image;
    if (!image) {
        image = [self dequeueReusableAnnotationImageWithIdentifier:MHDefaultStyleMarkerSymbolName].image;
    }
    if (!image) {
        return NSZeroRect;
    }

    NSRect positioningRect = [self frameOfImage:image centeredAtCoordinate:annotation.coordinate];
    positioningRect = NSOffsetRect(image.alignmentRect, positioningRect.origin.x, positioningRect.origin.y);
    return NSInsetRect(positioningRect, -MHAnnotationImagePaddingForCallout,
                       -MHAnnotationImagePaddingForCallout);
}

/// Returns the rectangle relative to the viewport that represents the given
/// image centered at the given coordinate.
- (NSRect)frameOfImage:(NSImage *)image centeredAtCoordinate:(CLLocationCoordinate2D)coordinate {
    NSPoint calloutAnchorPoint = [self convertCoordinate:coordinate toPointToView:self];
    return NSInsetRect({ calloutAnchorPoint, NSZeroSize }, -image.size.width / 2, -image.size.height / 2);
}

/// Returns the annotation image assigned to the annotation with the given tag.
- (MHAnnotationImage *)imageOfAnnotationWithTag:(MHAnnotationTag)annotationTag {
    if (annotationTag == MHAnnotationTagNotFound
        || _annotationContextsByAnnotationTag.count(annotationTag) == 0) {
        return nil;
    }

    NSString *customSymbol = _annotationContextsByAnnotationTag.at(annotationTag).imageReuseIdentifier;
    NSString *symbolName = customSymbol.length ? customSymbol : MHDefaultStyleMarkerSymbolName;

    return [self dequeueReusableAnnotationImageWithIdentifier:symbolName];
}

- (void)deselectAnnotation:(id <MHAnnotation>)annotation {
    if (!annotation || self.selectedAnnotation != annotation) {
        return;
    }

    // Close the callout popover gracefully.
    NSPopover *callout = self.calloutForSelectedAnnotation;
    [callout performClose:self];

    self.selectedAnnotation = nil;
}

/// Move the annotation callout to point to the selected annotation at its
/// current position.
- (void)updateAnnotationCallouts {
    NSPopover *callout = self.calloutForSelectedAnnotation;
    if (callout) {
        NSRect rect = [self positioningRectForCalloutForAnnotationWithTag:_selectedAnnotationTag];

        NSAssert(!NSEqualRects(rect, NSZeroRect), @"Positioning rect should be non-zero");

        if (!NSIsEmptyRect(NSIntersectionRect(rect, self.bounds))) {

            // It's possible that the current callout hasn't been presented (since the original
            // positioningRect was offscreen). We can check that the callout has a valid window
            // This results in the callout being presented just as the annotation comes on screen
            // which matches MapKit, but (currently) not iOS.
            if (!callout.contentViewController.view.window) {
                NSRectEdge edge = (self.userInterfaceLayoutDirection == NSUserInterfaceLayoutDirectionRightToLeft
                                   ? NSMinXEdge
                                   : NSMaxXEdge);
                // Re-present the callout
                [callout showRelativeToRect:rect ofView:self preferredEdge:edge];
            }
            else {
                callout.positioningRect = rect;
            }
        }
    }
}

// MARK: MHMultiPointDelegate methods

- (double)alphaForShapeAnnotation:(MHShape *)annotation {
    if (_delegateHasAlphasForShapeAnnotations) {
        return [self.delegate mapView:self alphaForShapeAnnotation:annotation];
    }
    return 1.0;
}

- (mbgl::Color)strokeColorForShapeAnnotation:(MHShape *)annotation {
    NSColor *color = (_delegateHasStrokeColorsForShapeAnnotations
                      ? [self.delegate mapView:self strokeColorForShapeAnnotation:annotation]
                      : [NSColor selectedMenuItemColor]);
    return color.mgl_color;
}

- (mbgl::Color)fillColorForPolygonAnnotation:(MHPolygon *)annotation {
    NSColor *color = (_delegateHasFillColorsForShapeAnnotations
                      ? [self.delegate mapView:self fillColorForPolygonAnnotation:annotation]
                      : [NSColor selectedMenuItemColor]);
    return color.mgl_color;
}

- (CGFloat)lineWidthForPolylineAnnotation:(MHPolyline *)annotation {
    if (_delegateHasLineWidthsForShapeAnnotations) {
        return [self.delegate mapView:self lineWidthForPolylineAnnotation:(MHPolyline *)annotation];
    }
    return 3.0;
}

// MARK: MHPopoverDelegate methods

- (void)popoverDidShow:(__unused NSNotification *)notification {
    id <MHAnnotation> annotation = self.selectedAnnotation;
    if (annotation && [self.delegate respondsToSelector:@selector(mapView:didSelectAnnotation:)]) {
        [self.delegate mapView:self didSelectAnnotation:annotation];
    }
}

- (void)popoverDidClose:(__unused NSNotification *)notification {
    // Deselect the closed popover, in case the popover was closed due to user
    // action.
    id <MHAnnotation> annotation = self.calloutForSelectedAnnotation.contentViewController.representedObject;
    self.calloutForSelectedAnnotation = nil;
    self.selectedAnnotation = nil;

    if ([self.delegate respondsToSelector:@selector(mapView:didDeselectAnnotation:)]) {
        [self.delegate mapView:self didDeselectAnnotation:annotation];
    }
}

// MARK: Overlays

- (nonnull NSArray<id <MHOverlay>> *)overlays
{
    if (self.annotations == nil) { return @[]; }

    NSMutableArray<id <MHOverlay>> *mutableOverlays = [NSMutableArray array];

    [self.annotations enumerateObjectsUsingBlock:^(id<MHAnnotation>  _Nonnull annotation, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([annotation conformsToProtocol:@protocol(MHOverlay)])
        {
            [mutableOverlays addObject:(id<MHOverlay>)annotation];
        }
    }];

    return [NSArray arrayWithArray:mutableOverlays];
}

- (void)addOverlay:(id <MHOverlay>)overlay {
    MHLogDebug(@"Adding overlay: %@", overlay);
    [self addOverlays:@[overlay]];
}

- (void)addOverlays:(NSArray<id <MHOverlay>> *)overlays
{
    MHLogDebug(@"Adding: %lu overlays", overlays.count);
#if DEBUG
    for (id <MHOverlay> overlay in overlays) {
        NSAssert([overlay conformsToProtocol:@protocol(MHOverlay)], @"Overlay does not conform to MHOverlay");
    }
#endif
    [self addAnnotations:overlays];
}

- (void)removeOverlay:(id <MHOverlay>)overlay {
    MHLogDebug(@"Removing overlay: %@", overlay);
    [self removeOverlays:@[overlay]];
}

- (void)removeOverlays:(NSArray<id <MHOverlay>> *)overlays {
    MHLogDebug(@"Removing: %lu overlays", overlays.count);
#if DEBUG
    for (id <MHOverlay> overlay in overlays) {
        NSAssert([overlay conformsToProtocol:@protocol(MHOverlay)], @"Overlay does not conform to MHOverlay");
    }
#endif
    [self removeAnnotations:overlays];
}

// MARK: Tooltips and cursors

- (void)updateAnnotationTrackingAreas {
    if (_wantsToolTipRects) {
        [self removeAllToolTips];
        std::vector<MHAnnotationTag> annotationTags = [self annotationTagsInRect:self.bounds];
        for (MHAnnotationTag annotationTag : annotationTags) {
            MHAnnotationImage *annotationImage = [self imageOfAnnotationWithTag:annotationTag];
            id <MHAnnotation> annotation = [self annotationWithTag:annotationTag];
            if ([annotation respondsToSelector:@selector(toolTip)] && annotation.toolTip.length) {
                // Add a tooltip tracking area over the annotation image’s
                // frame, accounting for the image’s alignment rect.
                NSImage *image = annotationImage.image;
                NSRect annotationRect = [self frameOfImage:image
                                      centeredAtCoordinate:annotation.coordinate];
                annotationRect = NSOffsetRect(image.alignmentRect, annotationRect.origin.x, annotationRect.origin.y);
                if (!NSIsEmptyRect(annotationRect)) {
                    [self addToolTipRect:annotationRect owner:self userData:(void *)(NSUInteger)annotationTag];
                }
            }
            // Opt into potentially expensive cursor tracking areas.
            if (annotationImage.cursor) {
                _wantsCursorRects = YES;
            }
        }
    }

    // Blow away any cursor tracking areas and rebuild them. That’s the
    // potentially expensive part.
    if (_wantsCursorRects) {
        [self.window invalidateCursorRectsForView:self];
    }
}

- (NSString *)view:(__unused NSView *)view stringForToolTip:(__unused NSToolTipTag)tag point:(__unused NSPoint)point userData:(void *)data {
    NSAssert((NSUInteger)data < MHAnnotationTagNotFound, @"Invalid annotation tag in tooltip rect user data.");
    MHAnnotationTag annotationTag = (MHAnnotationTag)MIN((NSUInteger)data, MHAnnotationTagNotFound);
    id <MHAnnotation> annotation = [self annotationWithTag:annotationTag];
    return annotation.toolTip;
}

- (void)resetCursorRects {
    // Drag to pan has a grabbing hand cursor.
    if ([self isPanningWithGesture]) {
        [self addCursorRect:self.bounds cursor:[NSCursor closedHandCursor]];
        return;
    }

    // The rest of this method can be expensive, so bail if no annotations have
    // ever had custom cursors.
    if (!_wantsCursorRects) {
        return;
    }

    std::vector<MHAnnotationTag> annotationTags = [self annotationTagsInRect:self.bounds];
    for (MHAnnotationTag annotationTag : annotationTags) {
        id <MHAnnotation> annotation = [self annotationWithTag:annotationTag];
        MHAnnotationImage *annotationImage = [self imageOfAnnotationWithTag:annotationTag];
        if (annotationImage.cursor) {
            // Add a cursor tracking area over the annotation image, respecting
            // the image’s alignment rect.
            NSImage *image = annotationImage.image;
            NSRect annotationRect = [self frameOfImage:image
                                  centeredAtCoordinate:annotation.coordinate];
            annotationRect = NSOffsetRect(image.alignmentRect, annotationRect.origin.x, annotationRect.origin.y);
            [self addCursorRect:annotationRect cursor:annotationImage.cursor];
        }
    }
}

// MARK: Data

- (NSArray<id <MHFeature>> *)visibleFeaturesAtPoint:(NSPoint)point {
    MHLogDebug(@"Querying visibleFeaturesAtPoint: %@", NSStringFromPoint(point));
    return [self visibleFeaturesAtPoint:point inStyleLayersWithIdentifiers:nil];
}

- (NSArray<id <MHFeature>> *)visibleFeaturesAtPoint:(CGPoint)point inStyleLayersWithIdentifiers:(NSSet<NSString *> *)styleLayerIdentifiers {
    MHLogDebug(@"Querying visibleFeaturesAtPoint: %@ inStyleLayersWithIdentifiers: %@", NSStringFromPoint(point), styleLayerIdentifiers);
    return [self visibleFeaturesAtPoint:point inStyleLayersWithIdentifiers:styleLayerIdentifiers predicate:nil];
}

- (NSArray<id <MHFeature>> *)visibleFeaturesAtPoint:(NSPoint)point inStyleLayersWithIdentifiers:(NSSet<NSString *> *)styleLayerIdentifiers predicate:(NSPredicate *)predicate {
    MHLogDebug(@"Querying visibleFeaturesAtPoint: %@ inStyleLayersWithIdentifiers: %@ predicate: %@", NSStringFromPoint(point), styleLayerIdentifiers, predicate);
    // Cocoa origin is at the lower-left corner.
    mbgl::ScreenCoordinate screenCoordinate = { point.x, NSHeight(self.bounds) - point.y };

    std::optional<std::vector<std::string>> optionalLayerIDs;
    if (styleLayerIdentifiers) {
        __block std::vector<std::string> layerIDs;
        layerIDs.reserve(styleLayerIdentifiers.count);
        [styleLayerIdentifiers enumerateObjectsUsingBlock:^(NSString * _Nonnull identifier, BOOL * _Nonnull stop) {
            layerIDs.push_back(identifier.UTF8String);
        }];
        optionalLayerIDs = layerIDs;
    }
    
    std::optional<mbgl::style::Filter> optionalFilter;
    if (predicate) {
        optionalFilter = predicate.mgl_filter;
    }
    
    std::vector<mbgl::Feature> features = _rendererFrontend->getRenderer()->queryRenderedFeatures(screenCoordinate, { optionalLayerIDs, optionalFilter });
    return MHFeaturesFromMBGLFeatures(features);
}

- (NSArray<id <MHFeature>> *)visibleFeaturesInRect:(NSRect)rect {
    MHLogDebug(@"Querying visibleFeaturesInRect: %@", NSStringFromRect(rect));
    return [self visibleFeaturesInRect:rect inStyleLayersWithIdentifiers:nil];
}

- (NSArray<id <MHFeature>> *)visibleFeaturesInRect:(CGRect)rect inStyleLayersWithIdentifiers:(NSSet<NSString *> *)styleLayerIdentifiers {
    MHLogDebug(@"Querying visibleFeaturesInRect: %@ inStyleLayersWithIdentifiers: %@", NSStringFromRect(rect), styleLayerIdentifiers);
    return [self visibleFeaturesInRect:rect inStyleLayersWithIdentifiers:styleLayerIdentifiers predicate:nil];
}

- (NSArray<id <MHFeature>> *)visibleFeaturesInRect:(NSRect)rect inStyleLayersWithIdentifiers:(NSSet<NSString *> *)styleLayerIdentifiers predicate:(NSPredicate *)predicate {
    MHLogDebug(@"Querying visibleFeaturesInRect: %@ inStyleLayersWithIdentifiers: %@ predicate: %@", NSStringFromRect(rect), styleLayerIdentifiers, predicate);
    // Cocoa origin is at the lower-left corner.
    mbgl::ScreenBox screenBox = {
        { NSMinX(rect), NSHeight(self.bounds) - NSMaxY(rect) },
        { NSMaxX(rect), NSHeight(self.bounds) - NSMinY(rect) },
    };

    std::optional<std::vector<std::string>> optionalLayerIDs;
    if (styleLayerIdentifiers) {
        __block std::vector<std::string> layerIDs;
        layerIDs.reserve(styleLayerIdentifiers.count);
        [styleLayerIdentifiers enumerateObjectsUsingBlock:^(NSString * _Nonnull identifier, BOOL * _Nonnull stop) {
            layerIDs.push_back(identifier.UTF8String);
        }];
        optionalLayerIDs = layerIDs;
    }
    
    std::optional<mbgl::style::Filter> optionalFilter;
    if (predicate) {
        optionalFilter = predicate.mgl_filter;
    }
    
    std::vector<mbgl::Feature> features = _rendererFrontend->getRenderer()->queryRenderedFeatures(screenBox, { optionalLayerIDs, optionalFilter });
    return MHFeaturesFromMBGLFeatures(features);
}

// MARK: User interface validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    return NO;
}

// MARK: Interface Builder methods

- (void)prepareForInterfaceBuilder {
    [super prepareForInterfaceBuilder];

    // Color the background a glorious Mapbox teal.
    self.layer.borderColor = [NSColor colorWithRed:59/255.
                                             green:178/255.
                                              blue:208/255.
                                             alpha:0.8].CGColor;
    self.layer.borderWidth = 2;
    self.layer.backgroundColor = [NSColor colorWithRed:59/255.
                                                 green:178/255.
                                                  blue:208/255.
                                                 alpha:0.6].CGColor;

    // Place a playful marker right smack dab in the middle.
    self.layer.contents = MHDefaultMarkerImage();
    self.layer.contentsGravity = kCAGravityCenter;
    self.layer.contentsScale = [NSScreen mainScreen].backingScaleFactor;
}

// MARK: Geometric methods

- (NSPoint)convertCoordinate:(CLLocationCoordinate2D)coordinate toPointToView:(nullable NSView *)view {
    if (!CLLocationCoordinate2DIsValid(coordinate)) {
        return NSMakePoint(NAN, NAN);
    }
    return [self convertLatLng:MHLatLngFromLocationCoordinate2D(coordinate) toPointToView:view];
}

/// Converts a geographic coordinate to a point in the view’s coordinate system.
- (NSPoint)convertLatLng:(mbgl::LatLng)latLng toPointToView:(nullable NSView *)view {
    mbgl::ScreenCoordinate pixel = _mbglMap->pixelForLatLng(latLng);
    // Cocoa origin is at the lower-left corner.
    pixel.y = NSHeight(self.bounds) - pixel.y;
    return [self convertPoint:NSMakePoint(pixel.x, pixel.y) toView:view];
}

- (CLLocationCoordinate2D)convertPoint:(NSPoint)point toCoordinateFromView:(nullable NSView *)view {
    return MHLocationCoordinate2DFromLatLng([self convertPoint:point toLatLngFromView:view]);
}

/// Converts a point in the view’s coordinate system to a geographic coordinate.
- (mbgl::LatLng)convertPoint:(NSPoint)point toLatLngFromView:(nullable NSView *)view {
    NSPoint convertedPoint = [self convertPoint:point fromView:view];
    return _mbglMap->latLngForPixel({
        convertedPoint.x,
        // mbgl origin is at the top-left corner.
        NSHeight(self.bounds) - convertedPoint.y,
    }).wrapped();
}

- (NSRect)convertCoordinateBounds:(MHCoordinateBounds)bounds toRectToView:(nullable NSView *)view {
    return [self convertLatLngBounds:MHLatLngBoundsFromCoordinateBounds(bounds) toRectToView:view];
}

/// Converts a geographic bounding box to a rectangle in the view’s coordinate
/// system.
- (NSRect)convertLatLngBounds:(mbgl::LatLngBounds)bounds toRectToView:(nullable NSView *)view {
    auto northwest = bounds.northwest();
    auto northeast = bounds.northeast();
    auto southwest = bounds.southwest();
    auto southeast = bounds.southeast();

    auto center = [self convertPoint:{ NSMidX(view.bounds), NSMidY(view.bounds) } toLatLngFromView:view];
    
    // Extend bounds to account for the antimeridian
    northwest.unwrapForShortestPath(center);
    northeast.unwrapForShortestPath(center);
    southwest.unwrapForShortestPath(center);
    southeast.unwrapForShortestPath(center);
    
    auto correctedLatLngBounds = mbgl::LatLngBounds::empty();
    correctedLatLngBounds.extend(northwest);
    correctedLatLngBounds.extend(northeast);
    correctedLatLngBounds.extend(southwest);
    correctedLatLngBounds.extend(southeast);
    
    NSRect rect = { [self convertLatLng:correctedLatLngBounds.southwest() toPointToView:view], CGSizeZero };
    rect = MHExtendRect(rect, [self convertLatLng:correctedLatLngBounds.northeast() toPointToView:view]);
    return rect;
}

- (MHCoordinateBounds)convertRect:(NSRect)rect toCoordinateBoundsFromView:(nullable NSView *)view {
    return MHCoordinateBoundsFromLatLngBounds([self convertRect:rect toLatLngBoundsFromView:view]);
}

/// Converts a rectangle in the given view’s coordinate system to a geographic
/// bounding box.
- (mbgl::LatLngBounds)convertRect:(NSRect)rect toLatLngBoundsFromView:(nullable NSView *)view {
    auto bounds = mbgl::LatLngBounds::empty();
    auto bottomLeft = [self convertPoint:{ NSMinX(rect), NSMinY(rect) } toLatLngFromView:view];
    auto bottomRight = [self convertPoint:{ NSMaxX(rect), NSMinY(rect) } toLatLngFromView:view];
    auto topRight = [self convertPoint:{ NSMaxX(rect), NSMaxY(rect) } toLatLngFromView:view];
    auto topLeft = [self convertPoint:{ NSMinX(rect), NSMaxY(rect) } toLatLngFromView:view];
    
    // If the bounds straddles the antimeridian, unwrap it so that one side
    // extends beyond ±180° longitude.
    auto center = [self convertPoint:{ NSMidX(rect), NSMidY(rect) } toLatLngFromView:view];
    bottomLeft.unwrapForShortestPath(center);
    bottomRight.unwrapForShortestPath(center);
    topRight.unwrapForShortestPath(center);
    topLeft.unwrapForShortestPath(center);
    
    bounds.extend(bottomLeft);
    bounds.extend(bottomRight);
    bounds.extend(topRight);
    bounds.extend(topLeft);

    return bounds;
}

- (CLLocationDistance)metersPerPointAtLatitude:(CLLocationDegrees)latitude {
    return mbgl::Projection::getMetersPerPixelAtLatitude(latitude, self.zoomLevel);
}

// MARK: Debugging

- (MHMapDebugMaskOptions)debugMask {
    mbgl::MapDebugOptions options = _mbglMap->getDebug();
    MHMapDebugMaskOptions mask = 0;
    if (options & mbgl::MapDebugOptions::TileBorders) {
        mask |= MHMapDebugTileBoundariesMask;
    }
    if (options & mbgl::MapDebugOptions::ParseStatus) {
        mask |= MHMapDebugTileInfoMask;
    }
    if (options & mbgl::MapDebugOptions::Timestamps) {
        mask |= MHMapDebugTimestampsMask;
    }
    if (options & mbgl::MapDebugOptions::Collision) {
        mask |= MHMapDebugCollisionBoxesMask;
    }
    if (options & mbgl::MapDebugOptions::Overdraw) {
        mask |= MHMapDebugOverdrawVisualizationMask;
    }
    if (options & mbgl::MapDebugOptions::StencilClip) {
        mask |= MHMapDebugStencilBufferMask;
    }
    if (options & mbgl::MapDebugOptions::DepthBuffer) {
        mask |= MHMapDebugDepthBufferMask;
    }
    return mask;
}

- (void)setDebugMask:(MHMapDebugMaskOptions)debugMask {
    mbgl::MapDebugOptions options = mbgl::MapDebugOptions::NoDebug;
    if (debugMask & MHMapDebugTileBoundariesMask) {
        options |= mbgl::MapDebugOptions::TileBorders;
    }
    if (debugMask & MHMapDebugTileInfoMask) {
        options |= mbgl::MapDebugOptions::ParseStatus;
    }
    if (debugMask & MHMapDebugTimestampsMask) {
        options |= mbgl::MapDebugOptions::Timestamps;
    }
    if (debugMask & MHMapDebugCollisionBoxesMask) {
        options |= mbgl::MapDebugOptions::Collision;
    }
    if (debugMask & MHMapDebugOverdrawVisualizationMask) {
        options |= mbgl::MapDebugOptions::Overdraw;
    }
    if (debugMask & MHMapDebugStencilBufferMask) {
        options |= mbgl::MapDebugOptions::StencilClip;
    }
    if (debugMask & MHMapDebugDepthBufferMask) {
        options |= mbgl::MapDebugOptions::DepthBuffer;
    }
    _mbglMap->setDebug(options);
}

@end
