#import "MHAnnotationView.h"
#import "MHAnnotationView_Private.h"
#import "MHMapView_Private.h"
#import "MHCalloutView.h"
#import "MHAnnotation.h"
#import "MHPointAnnotation.h"
#import "MHLoggingConfiguration_Private.h"

#import "NSBundle+MHAdditions.h"
#import "NSValue+MHAdditions.h"

#include <mbgl/util/constants.hpp>

@interface MHAnnotationView () <UIGestureRecognizerDelegate>

@property (nonatomic, readwrite, nullable) NSString *reuseIdentifier;
@property (nonatomic, readwrite) CATransform3D lastAppliedScaleTransform;
@property (nonatomic, readwrite) CGFloat lastPitch;
@property (nonatomic, readwrite) CATransform3D lastAppliedRotationTransform;
@property (nonatomic, readwrite) CGFloat lastDirection;
@property (nonatomic, weak) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, weak) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, weak) MHMapView *mapView;

@end

@implementation MHAnnotationView

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    MHLogDebug(@"Initializing with identifier: %@", reuseIdentifier);
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self commonInitWithAnnotation:nil reuseIdentifier:reuseIdentifier];
    }
    return self;
}

- (instancetype)initWithAnnotation:(nullable id<MHAnnotation>)annotation reuseIdentifier:(nullable NSString *)reuseIdentifier {
    MHLogDebug(@"Initializing with annotation: %@ reuseIdentifier: %@", annotation, reuseIdentifier);
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self commonInitWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    }
    return self;
}

- (void)commonInitWithAnnotation:(nullable id<MHAnnotation>)annotation reuseIdentifier:(nullable NSString *)reuseIdentifier {
    _lastAppliedScaleTransform = CATransform3DIdentity;
    _lastAppliedRotationTransform = CATransform3DIdentity;
    _annotation = annotation;
    _reuseIdentifier = [reuseIdentifier copy];
    _enabled = YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    MHLogInfo(@"Initializing with coder.");
    if (self = [super initWithCoder:decoder]) {
        _reuseIdentifier = [decoder decodeObjectOfClass:[NSString class] forKey:@"reuseIdentifier"];
        _annotation = [decoder decodeObjectOfClass:[NSObject class] forKey:@"annotation"];
        _centerOffset = [decoder decodeCGVectorForKey:@"centerOffset"];
        _scalesWithViewingDistance = [decoder decodeBoolForKey:@"scalesWithViewingDistance"];
        _rotatesToMatchCamera = [decoder decodeBoolForKey:@"rotatesToMatchCamera"];
        _selected = [decoder decodeBoolForKey:@"selected"];
        _enabled = [decoder decodeBoolForKey:@"enabled"];
        self.draggable = [decoder decodeBoolForKey:@"draggable"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:_reuseIdentifier forKey:@"reuseIdentifier"];
    [coder encodeObject:_annotation forKey:@"annotation"];
    [coder encodeCGVector:_centerOffset forKey:@"centerOffset"];
    [coder encodeBool:_scalesWithViewingDistance forKey:@"scalesWithViewingDistance"];
    [coder encodeBool:_rotatesToMatchCamera forKey:@"rotatesToMatchCamera"];
    [coder encodeBool:_selected forKey:@"selected"];
    [coder encodeBool:_enabled forKey:@"enabled"];
    [coder encodeBool:_draggable forKey:@"draggable"];
}

- (void)prepareForReuse
{
    // Intentionally left blank. The default implementation of this method does nothing.
}

- (void)setCenterOffset:(CGVector)centerOffset
{
    MHLogDebug(@"Setting centerOffset: %@", NSStringFromCGVector(centerOffset));
    _centerOffset = centerOffset;
    self.center = self.center;
}

- (void)setSelected:(BOOL)selected
{
    MHLogDebug(@"Setting selected: %@", MHStringFromBOOL(selected));
    [self setSelected:selected animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    MHLogDebug(@"Setting selected: %@ animated: %@", MHStringFromBOOL(selected), MHStringFromBOOL(animated));
    [self willChangeValueForKey:@"selected"];
    _selected = selected;
    [self didChangeValueForKey:@"selected"];
}

- (CGPoint)center
{
    CGPoint center = super.center;
    center.x -= _centerOffset.dx;
    center.y -= _centerOffset.dy;
    return center;
}

- (void)setCenter:(CGPoint)center
{
    MHLogDebug(@"Setting center: %@", NSStringFromCGPoint(center));
    center.x += _centerOffset.dx;
    center.y += _centerOffset.dy;

    super.center = center;
    [self updateScaleTransformForViewingDistance];
    [self updateRotateTransform];
}

- (void)setScalesWithViewingDistance:(BOOL)scalesWithViewingDistance
{
    MHLogDebug(@"Setting scaleWithViewingDistance: %@", MHStringFromBOOL(scalesWithViewingDistance));
    if (_scalesWithViewingDistance != scalesWithViewingDistance)
    {
        _scalesWithViewingDistance = scalesWithViewingDistance;
        [self updateScaleTransformForViewingDistance];
    }
}

- (void)updateScaleTransformForViewingDistance
{
    if (self.scalesWithViewingDistance == NO || self.dragState == MHAnnotationViewDragStateDragging) return;

    CGFloat superviewHeight = CGRectGetHeight(self.superview.frame);
    if (superviewHeight > 0.0) {
        // Find the maximum amount of scale reduction to apply as the view's center moves from the top
        // of the superview to the bottom. For example, if this view's center has moved 25% of the way
        // from the top of the superview towards the bottom then the maximum scale reduction is 1 - .25
        // or 75%. The range goes from a maximum of 100% to 0% as the view moves from the top to the bottom
        // along the y axis of its superview.
        CGFloat maxScaleReduction = 1.0 - self.center.y / superviewHeight;

        // Since it is possible for the map view to report a pitch less than 0 due to the nature of
        // how the gesture information is captured, the value is guarded with MAX.
        CGFloat pitch = MAX(self.mapView.camera.pitch, 0);

        // Return early if the map view currently has no pitch and was not previously pitched.
        if (!pitch && !_lastPitch) return;
        _lastPitch = pitch;

        // The pitch intensity represents how much the map view is actually pitched compared to
        // what is possible. The value will range from 0% (not pitched at all) to 100% (pitched as much
        // as the map view will allow). The map view's maximum pitch is defined in `mbgl::util::PITCH_MAX`.
        CGFloat pitchIntensity = pitch / MHDegreesFromRadians(mbgl::util::PITCH_MAX);

        // The pitch adjusted scale is the inverse proportion of the maximum possible scale reduction
        // multiplied by the pitch intensity. For example, if the maximum scale reduction is 75% and the
        // map view is 50% pitched then the annotation view should be reduced by 37.5% (.75 * .5). The
        // reduction is then normalized for a scale of 1.0.
        CGFloat pitchAdjustedScale = 1.0 - maxScaleReduction * pitchIntensity;

        // We keep track of each viewing distance scale transform that we apply. Each iteration,
        // we can account for it so that we don't get cumulative scaling every time we move.
        // We also avoid clobbering any existing transform passed in by the client or this SDK.
        CATransform3D undoOfLastScaleTransform = CATransform3DInvert(_lastAppliedScaleTransform);
        CATransform3D newScaleTransform = CATransform3DMakeScale(pitchAdjustedScale, pitchAdjustedScale, 1);
        CATransform3D effectiveTransform = CATransform3DConcat(undoOfLastScaleTransform, newScaleTransform);
        self.layer.transform = CATransform3DConcat(self.layer.transform, effectiveTransform);
        _lastAppliedScaleTransform = newScaleTransform;
    }
}

- (void)setRotatesToMatchCamera:(BOOL)rotatesToMatchCamera
{
    MHLogDebug(@"Setting rotatesToMatchCamera: %@", MHStringFromBOOL(rotatesToMatchCamera));
    if (_rotatesToMatchCamera != rotatesToMatchCamera)
    {
        _rotatesToMatchCamera = rotatesToMatchCamera;
        [self updateRotateTransform];
    }
}

- (void)updateRotateTransform
{
    if (self.rotatesToMatchCamera == NO) return;

    CGFloat direction = -MHRadiansFromDegrees(self.mapView.direction);

    // Return early if the map view has the same rotation as the already-applied transform.
    if (direction == _lastDirection) return;
    _lastDirection = direction;

    // We keep track of each rotation transform that we apply. Each iteration,
    // we can account for it so that we don't get cumulative rotation every time we move.
    // We also avoid clobbering any existing transform passed in by the client or this SDK.
    CATransform3D undoOfLastRotationTransform = CATransform3DInvert(_lastAppliedRotationTransform);
    CATransform3D newRotationTransform = CATransform3DMakeRotation(direction, 0, 0, 1);
    CATransform3D effectiveTransform = CATransform3DConcat(undoOfLastRotationTransform, newRotationTransform);
    self.layer.transform = CATransform3DConcat(self.layer.transform, effectiveTransform);
    _lastAppliedRotationTransform = newRotationTransform;
}

// MARK: - Draggable

- (void)setDraggable:(BOOL)draggable
{
    MHLogDebug(@"Setting draggable: %@", MHStringFromBOOL(draggable));
    [self willChangeValueForKey:@"draggable"];
    _draggable = draggable;
    [self didChangeValueForKey:@"draggable"];

    if (draggable)
    {
        [self enableDrag];
    }
    else
    {
        [self disableDrag];
    }
}

- (void)enableDrag
{
    if (!_longPressRecognizer)
    {
        UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        recognizer.delegate = self;
        [self addGestureRecognizer:recognizer];
        _longPressRecognizer = recognizer;
    }

    if (!_panGestureRecognizer)
    {
        UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        recognizer.delegate = self;
        [self addGestureRecognizer:recognizer];
        _panGestureRecognizer = recognizer;
    }
}

- (void)disableDrag
{
    [self removeGestureRecognizer:_longPressRecognizer];
    [self removeGestureRecognizer:_panGestureRecognizer];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)sender
{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            self.dragState = MHAnnotationViewDragStateStarting;
            break;
        case UIGestureRecognizerStateChanged:
            self.dragState = MHAnnotationViewDragStateDragging;
            break;
        case UIGestureRecognizerStateCancelled:
            self.dragState = MHAnnotationViewDragStateCanceling;
            break;
        case UIGestureRecognizerStateEnded:
            self.dragState = MHAnnotationViewDragStateEnding;
            break;
        case UIGestureRecognizerStateFailed:
            self.dragState = MHAnnotationViewDragStateNone;
            break;
        case UIGestureRecognizerStatePossible:
            break;
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)sender
{
    self.center = [sender locationInView:sender.view.superview];

    if (sender.state == UIGestureRecognizerStateEnded) {
        self.dragState = MHAnnotationViewDragStateNone;
    }
}

- (void)setDragState:(MHAnnotationViewDragState)dragState
{
    MHLogDebug(@"Setting dragState: %lu", (unsigned long)dragState);
    [self setDragState:dragState animated:YES];
}

- (void)setDragState:(MHAnnotationViewDragState)dragState animated:(BOOL)animated
{
    MHLogDebug(@"Setting dragState: %lu animated: %@", (unsigned long)dragState, MHStringFromBOOL(animated));
    [self willChangeValueForKey:@"dragState"];
    _dragState = dragState;
    [self didChangeValueForKey:@"dragState"];

    if (dragState == MHAnnotationViewDragStateStarting)
    {
        [self.mapView.calloutViewForSelectedAnnotation dismissCalloutAnimated:animated];
        [self.superview bringSubviewToFront:self];
    }
    else if (dragState == MHAnnotationViewDragStateCanceling)
    {
        if (!self.annotation) {
            [NSException raise:NSInvalidArgumentException
                        format:@"Annotation property should not be nil."];
        }
        self.panGestureRecognizer.enabled = NO;
        self.longPressRecognizer.enabled = NO;
        self.center = [self.mapView convertCoordinate:self.annotation.coordinate toPointToView:self.mapView];
        self.panGestureRecognizer.enabled = YES;
        self.longPressRecognizer.enabled = YES;
        self.dragState = MHAnnotationViewDragStateNone;
    }
    else if (dragState == MHAnnotationViewDragStateEnding)
    {
        if ([self.annotation respondsToSelector:@selector(setCoordinate:)])
        {
            CLLocationCoordinate2D coordinate = [self.mapView convertPoint:self.center toCoordinateFromView:self.mapView];
            [(NSObject *)self.annotation setValue:[NSValue valueWithMHCoordinate:coordinate] forKey:@"coordinate"];
        }
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL isDragging = self.dragState == MHAnnotationViewDragStateDragging;

    if (gestureRecognizer == _panGestureRecognizer && !(isDragging))
    {
        return NO;
    }

    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return otherGestureRecognizer == _longPressRecognizer || otherGestureRecognizer == _panGestureRecognizer;
}

// MARK: UIAccessibility methods

- (BOOL)isAccessibilityElement {
    return !self.hidden;
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitButton | UIAccessibilityTraitAdjustable;
}

- (NSString *)accessibilityLabel {
    return [self.annotation respondsToSelector:@selector(title)] ? self.annotation.title : super.accessibilityLabel;
}

- (NSString *)accessibilityValue {
    return [self.annotation respondsToSelector:@selector(subtitle)] ? self.annotation.subtitle : super.accessibilityValue;
}

- (NSString *)accessibilityHint {
    return NSLocalizedStringWithDefaultValue(@"ANNOTATION_A11Y_HINT", nil, nil, @"Shows more info", @"Accessibility hint");
}

- (CGRect)accessibilityFrame {
    CGRect accessibilityFrame = self.frame;
    CGRect minimumFrame = CGRectInset({ self.center, CGSizeZero },
                                      -MHAnnotationAccessibilityElementMinimumSize.width / 2,
                                      -MHAnnotationAccessibilityElementMinimumSize.height / 2);
    accessibilityFrame = CGRectUnion(accessibilityFrame, minimumFrame);
    return accessibilityFrame;
}

- (void)accessibilityIncrement {
    [self.superview accessibilityIncrement];
}

- (void)accessibilityDecrement {
    [self.superview accessibilityDecrement];
}

@end
