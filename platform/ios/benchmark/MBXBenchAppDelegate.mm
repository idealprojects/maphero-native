#import "Mapbox.h"

#import "MBXBenchAppDelegate.h"
#import "MBXBenchViewController.h"

@implementation MBXBenchAppDelegate

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {

#ifndef MH_LOGGING_DISABLED
    [MHLoggingConfiguration sharedConfiguration].loggingLevel = MHLoggingLevelFault;
#endif

    [MHSettings useWellKnownTileServer:MHMapTiler];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [MBXBenchViewController new];
    [self.window makeKeyAndVisible];

    return YES;
}

@end
