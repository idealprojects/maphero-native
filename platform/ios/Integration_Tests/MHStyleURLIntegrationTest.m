#import "MHMapViewIntegrationTest.h"

@interface MHStyleURLIntegrationTest : MHMapViewIntegrationTest
@end

@implementation MHStyleURLIntegrationTest

- (void)setUp {
    [super setUp];
    [MHSettings useWellKnownTileServer:MHMapTiler];
}

- (void)predefinedStylesLoadingTest {
    
    for (MHDefaultStyle* style in [MHStyle predefinedStyles]) {
        NSString* styleName = style.name;
        self.mapView.styleURL = [[MHStyle predefinedStyle:styleName] url];
        [self waitForMapViewToFinishLoadingStyleWithTimeout:5];
    }
}

@end
