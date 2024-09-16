#import "MHTileServerOptions.h"
#import "NSBundle+MHAdditions.h"

#if TARGET_OS_OSX
#import "NSProcessInfo+MHAdditions.h"
#endif

@implementation MHTileServerOptions

@synthesize baseURL;
@synthesize uriSchemeAlias;
@synthesize sourceTemplate;
@synthesize sourceDomainName;
@synthesize sourceVersionPrefix;
@synthesize styleTemplate;
@synthesize styleDomainName;
@synthesize styleVersionPrefix;
@synthesize spritesTemplate;
@synthesize spritesDomainName;
@synthesize spritesVersionPrefix;
@synthesize glyphsTemplate;
@synthesize glyphsDomainName;
@synthesize glyphsVersionPrefix;
@synthesize tileTemplate;
@synthesize tileDomainName;
@synthesize tileVersionPrefix;
@synthesize apiKeyParameterName;
@synthesize defaultStyles;
@synthesize defaultStyle;

@end
