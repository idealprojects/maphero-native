#import <Mapbox.h>

extern NSString *const MHApiKeyDefaultsKey;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *preferencesWindow;

// Normally, an application should respect the “Close windows when quitting an
// application” setting in the General pane of System Preferences. But the map
// would only be restored to its last opened location if the user quits the
// application using Quit and Keep Windows. An application that displays only a
// map should restore the last viewed map, like Maps.app does. These properties
// temporarily hold state for the next map window to be opened.

@property (assign) double pendingZoomLevel;
@property (copy) MHMapCamera *pendingCamera;
@property (assign) MHCoordinateBounds pendingVisibleCoordinateBounds;
@property (assign) double pendingMinimumZoomLevel;
@property (assign) double pendingMaximumZoomLevel;
@property (copy) NSURL *pendingStyleURL;
@property (assign) MHMapDebugMaskOptions pendingDebugMask;

- (void)watchOfflinePack:(MHOfflinePack *)pack;

@end
