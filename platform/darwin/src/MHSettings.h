#import <Foundation/Foundation.h>

#import "MHFoundation.h"
#import "MHTileServerOptions.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Well-known tile servers
 */
typedef NS_ENUM(NSUInteger, MHWellKnownTileServer) {
  /**
   Maptiler
   */
  MHMapTiler,
  /**
   MapLibre
   */
  MHMapLibre,
  /**
   Mapbox
   */
  MHMapbox
};

/**
 The ``MHSettings`` object provides a global way to set SDK properties such
 as apiKey, backend URL, etc.
 */
MH_EXPORT
@interface MHSettings : NSObject

// MARK: Tile Server Configuration

/**
 Tile server options
 */
@property (class, copy, nullable) MHTileServerOptions* tileServerOptions;

// MARK: Authorizing Access

/**
 The API Key used by all instances of ``MHMapView`` in the current application.
 Setting this property to a value of `nil` has no effect.

 > Note: You must set the API key before attempting to load any style which
    requires the token. Therefore, you should generally set it before creating an instance of
    ``MHMapView``. The recommended way to set an api key is to add an entry
    to your application’s Info.plist file with the key `MHApiKey``
    and the type `String`. Alternatively, you may call this method from your
    application delegate’s `-applicationDidFinishLaunching:` method.
 */
@property (class, copy, nullable) NSString* apiKey;

/**
 Instructs the SDk to use the give tile server
 */
+ (void)useWellKnownTileServer:(MHWellKnownTileServer)tileServer;

@end

NS_ASSUME_NONNULL_END
