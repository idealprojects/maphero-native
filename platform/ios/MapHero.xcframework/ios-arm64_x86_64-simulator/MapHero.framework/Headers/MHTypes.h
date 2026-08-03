#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

#import "MHFoundation.h"

#pragma once

#if TARGET_OS_IPHONE
@class UIImage;
#define MHImage UIImage
#else
@class NSImage;
#define MHImage NSImage
#endif

#if TARGET_OS_IPHONE
@class UIColor;
#define MHColor UIColor
#else
@class NSColor;
#define MHColor NSColor
#endif

NS_ASSUME_NONNULL_BEGIN

typedef NSString *MHExceptionName NS_TYPED_EXTENSIBLE_ENUM;

/**
 :nodoc: Generic exceptions used across multiple disparate classes. Exceptions
 that are unique to a class or class-cluster should be defined in those headers.
 */
FOUNDATION_EXTERN MH_EXPORT MHExceptionName const MHAbstractClassException;

/** Indicates an error occurred in the Mapbox SDK. */
FOUNDATION_EXTERN MH_EXPORT NSErrorDomain const MHErrorDomain;

/** Error constants for the Mapbox SDK. */
typedef NS_ENUM(NSInteger, MHErrorCode) {
  /** An unknown error occurred. */
  MHErrorCodeUnknown = -1,
  /** The resource could not be found. */
  MHErrorCodeNotFound = 1,
  /** The connection received an invalid server response. */
  MHErrorCodeBadServerResponse = 2,
  /** An attempt to establish a connection failed. */
  MHErrorCodeConnectionFailed = 3,
  /** A style parse error occurred while attempting to load the map. */
  MHErrorCodeParseStyleFailed = 4,
  /** An attempt to load the style failed. */
  MHErrorCodeLoadStyleFailed = 5,
  /** An error occurred while snapshotting the map. */
  MHErrorCodeSnapshotFailed = 6,
  /** Source is in use and cannot be removed */
  MHErrorCodeSourceIsInUseCannotRemove = 7,
  /** Source is in use and cannot be removed */
  MHErrorCodeSourceIdentifierMismatch = 8,
  /** An error occurred while modifying the offline storage database */
  MHErrorCodeModifyingOfflineStorageFailed = 9,
  /** Source is invalid and cannot be removed from the style (e.g. after a style change) */
  MHErrorCodeSourceCannotBeRemovedFromStyle = 10,
  /** An error occurred while rendering */
  MHErrorCodeRenderingError = 11,
};

/** Options for enabling debugging features in an ``MHMapView`` instance. */
typedef NS_OPTIONS(NSUInteger, MHMapDebugMaskOptions) {
  /** Edges of tile boundaries are shown as thick, red lines to help diagnose
      tile clipping issues. */
  MHMapDebugTileBoundariesMask = 1 << 1,
  /** Each tile shows its tile coordinate (x/y/z) in the upper-left corner. */
  MHMapDebugTileInfoMask = 1 << 2,
  /** Each tile shows a timestamp indicating when it was loaded. */
  MHMapDebugTimestampsMask = 1 << 3,
  /** Edges of glyphs and symbols are shown as faint, green lines to help
      diagnose collision and label placement issues. */
  MHMapDebugCollisionBoxesMask = 1 << 4,
  /** Each drawing operation is replaced by a translucent fill. Overlapping
      drawing operations appear more prominent to help diagnose overdrawing.
      > Note: This option does nothing in Release builds of the SDK. */
  MHMapDebugOverdrawVisualizationMask = 1 << 5,
#if !TARGET_OS_IPHONE
  /** The stencil buffer is shown instead of the color buffer.
      > Note: This option does nothing in Release builds of the SDK. */
  MHMapDebugStencilBufferMask = 1 << 6,
  /** The depth buffer is shown instead of the color buffer.
      > Note: This option does nothing in Release builds of the SDK. */
  MHMapDebugDepthBufferMask = 1 << 7,
#endif
};

/**
 A structure containing information about a transition.
 */
typedef struct __attribute__((objc_boxable)) MHTransition {
  /**
   The amount of time the animation should take, not including the delay.
   */
  NSTimeInterval duration;

  /**
   The amount of time in seconds to wait before beginning the animation.
   */
  NSTimeInterval delay;
} MHTransition;

NS_INLINE NSString *MHStringFromMHTransition(MHTransition transition) {
  return [NSString stringWithFormat:@"transition { duration: %f, delay: %f }", transition.duration,
                                    transition.delay];
}

/**
 Creates a new ``MHTransition`` from the given duration and delay.

 @param duration The amount of time the animation should take, not including
 the delay.
 @param delay The amount of time in seconds to wait before beginning the
 animation.

 @return Returns a ``MHTransition`` struct containing the transition attributes.
 */
NS_INLINE MHTransition MHTransitionMake(NSTimeInterval duration, NSTimeInterval delay) {
  MHTransition transition;
  transition.duration = duration;
  transition.delay = delay;

  return transition;
}

/**
 Constants indicating the visibility of different map ornaments.
 */
typedef NS_ENUM(NSInteger, MHOrnamentVisibility) {
  /** A constant indicating that the ornament adapts to the current map state. */
  MHOrnamentVisibilityAdaptive,
  /** A constant indicating that the ornament is always hidden. */
  MHOrnamentVisibilityHidden,
  /** A constant indicating that the ornament is always visible. */
  MHOrnamentVisibilityVisible
};

NS_ASSUME_NONNULL_END
