#import <Cocoa/Cocoa.h>

@class MHMapView;

@interface MapDocument : NSDocument

@property (weak) IBOutlet MHMapView *mapView;

- (IBAction)showStyle:(id)sender;
- (IBAction)chooseCustomStyle:(id)sender;

- (IBAction)reload:(id)sender;

@end
