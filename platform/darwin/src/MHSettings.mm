#import "MHSettings_Private.h"
#import "NSBundle+MHAdditions.h"

#if TARGET_OS_OSX
#import "NSProcessInfo+MHAdditions.h"
#endif

@interface MHSettings ()

@property (atomic) NSString *apiKey;
@property (atomic) mbgl::TileServerOptions *tileServerOptionsInternal;
@property (atomic) NSString *tileServerOptionsChangeToken;

@end

@implementation MHSettings

// MARK: - Internal

- (instancetype)init {
    if (self = [super init]) {
        self.tileServerOptionsInternal = new mbgl::TileServerOptions(mbgl::TileServerOptions::DefaultConfiguration());
    }
    return self;
}

+ (void)load {
    // Read the initial configuration from Info.plist.
    NSString *apiKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MHApiKey"];
    if (apiKey.length) {
        self.apiKey = apiKey;
    }

    NSString *apiBaseURL = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MHTileServerBaseURL"];
    
    // If apiBaseURL is not a valid URL, [NSURL URLWithString:] will be `nil`.
    if (apiBaseURL.length && [NSURL URLWithString:apiBaseURL]) {
        [self setAPIBaseURL:[NSURL URLWithString:apiBaseURL]];
        [self tileServerOptionsChanged];
    }
}

+ (instancetype)sharedSettings {
#if TARGET_OS_OSX
    if (NSProcessInfo.processInfo.mgl_isInterfaceBuilderDesignablesAgent) {
        return nil;
    }
#endif
    
    static dispatch_once_t onceToken;
    static MHSettings *_sharedSettings;
    void (^setupBlock)(void) = ^{
        dispatch_once(&onceToken, ^{
            _sharedSettings = [[self alloc] init];
        });
    };
    if (![[NSThread currentThread] isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            setupBlock();
        });
    } else {
        setupBlock();
    }
    return _sharedSettings;
}

+ (void)setApiKey:(NSString *)apiKey {
    apiKey = [apiKey stringByTrimmingCharactersInSet:
             [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!apiKey.length) {
        return;
    }

    [MHSettings sharedSettings].apiKey = apiKey;
}

+ (NSString *)apiKey {
    return [MHSettings sharedSettings].apiKey;
}

+ (void)setAPIBaseURL:(NSURL *)apiBaseURL {
    auto tileServerOptions = [MHSettings sharedSettings].tileServerOptionsInternal;
    NSString *baseUrlNSStr = apiBaseURL.absoluteString;
    auto baseUrl = std::string([baseUrlNSStr UTF8String]);

    [MHSettings sharedSettings].tileServerOptionsInternal = &tileServerOptions->withBaseURL(baseUrl);
}

+ (NSURL *)apiBaseURL {
    auto baseUrl = [MHSettings sharedSettings].tileServerOptionsInternal->baseURL();
    NSString* baseUrlNSStr = [NSString stringWithUTF8String:baseUrl.c_str()];
    NSURL *url = [NSURL URLWithString:baseUrlNSStr];
    return url;
}

+ (void)setTileServerOptionsInternal:(mbgl::TileServerOptions)options {
    [MHSettings sharedSettings].tileServerOptionsInternal = new mbgl::TileServerOptions();
    *[MHSettings sharedSettings].tileServerOptionsInternal = options.clone();
    [self tileServerOptionsChanged];
}

+ (mbgl::TileServerOptions)tileServerOptionsInternal {
    auto options = [MHSettings sharedSettings];
    return options.tileServerOptionsInternal->clone();
}

+ (void)tileServerOptionsChanged {
    [MHSettings sharedSettings].tileServerOptionsChangeToken = [[NSUUID UUID] UUIDString];
}

+ (void)useWellKnownTileServer:(MHWellKnownTileServer)tileServer {
    switch(tileServer){
        case MHMapTiler:
            [MHSettings setTileServerOptionsInternal:mbgl::TileServerOptions::MapTilerConfiguration()];
            break;
        case MHMapLibre:
            [MHSettings setTileServerOptionsInternal:mbgl::TileServerOptions::MapHeroConfiguration()];
            break;
        case MHMapbox:
            [MHSettings setTileServerOptionsInternal:mbgl::TileServerOptions::MapboxConfiguration()];
            break;
        default:
            [MHSettings setTileServerOptionsInternal:mbgl::TileServerOptions::DefaultConfiguration()];
    }
}

+ (void)setTileServerOptions:(MHTileServerOptions*)options {
    
    auto opts = mbgl::TileServerOptions()
            .withBaseURL(std::string([options.baseURL UTF8String]))
            .withUriSchemeAlias(std::string([options.uriSchemeAlias UTF8String]))
            .withApiKeyParameterName(std::string([options.apiKeyParameterName UTF8String]));

    opts.withSourceTemplate(
            std::string([options.sourceTemplate UTF8String]),
            std::string([options.sourceDomainName UTF8String]),
            options.sourceVersionPrefix ? std::string([options.sourceVersionPrefix UTF8String]) : std::optional<std::string>{});

    opts.withStyleTemplate(
            std::string([options.styleTemplate UTF8String]),
            std::string([options.styleDomainName UTF8String]),
            options.styleVersionPrefix ? std::string([options.styleVersionPrefix UTF8String]) : std::optional<std::string>{});

    opts.withSpritesTemplate(
            std::string([options.spritesTemplate UTF8String]),
            std::string([options.spritesDomainName UTF8String]),
            options.spritesVersionPrefix ? std::string([options.spritesVersionPrefix UTF8String]) : std::optional<std::string>{});

    opts.withGlyphsTemplate(
            std::string([options.glyphsTemplate UTF8String]),
            std::string([options.glyphsDomainName UTF8String]),
            options.glyphsVersionPrefix ? std::string([options.glyphsVersionPrefix UTF8String])  : std::optional<std::string>{});

    opts.withTileTemplate(
            std::string([options.tileTemplate UTF8String]),
            std::string([options.tileDomainName UTF8String]),
            options.tileVersionPrefix ? std::string([options.tileVersionPrefix UTF8String]) : std::optional<std::string>{});

    std::vector<mbgl::util::DefaultStyle> defaultStyles;
    if (options.defaultStyles) {
        for (MHDefaultStyle* objCStyle in options.defaultStyles) {
            mbgl::util::DefaultStyle cppStyle(
              std::string([objCStyle.url.absoluteString  UTF8String]),
              std::string([objCStyle.name UTF8String]),
              objCStyle.version
            );
            defaultStyles.push_back(cppStyle);
        }
    }
    opts.withDefaultStyles(defaultStyles);
    opts.withDefaultStyle(std::string([options.defaultStyle.name UTF8String]));
    
    self.tileServerOptionsInternal = opts;
}

+ (MHTileServerOptions*)tileServerOptions {
    auto cppOpts = [MHSettings sharedSettings].tileServerOptionsInternal;
    if (cppOpts) {
        
        MHTileServerOptions* retVal = [[MHTileServerOptions alloc] init];
        retVal.baseURL = [NSString stringWithUTF8String:cppOpts->baseURL().c_str()];
        retVal.uriSchemeAlias = [NSString stringWithUTF8String:cppOpts->uriSchemeAlias().c_str()];
        retVal.apiKeyParameterName = [NSString stringWithUTF8String:cppOpts->apiKeyParameterName().c_str()];
        
        retVal.sourceTemplate = [NSString stringWithUTF8String:cppOpts->sourceTemplate().c_str()];
        retVal.sourceDomainName = [NSString stringWithUTF8String:cppOpts->sourceDomainName().c_str()];
        retVal.sourceVersionPrefix = cppOpts->sourceVersionPrefix().has_value() ? [NSString stringWithUTF8String:cppOpts->sourceVersionPrefix().value().c_str()] : nil;
        
        retVal.styleTemplate = [NSString stringWithUTF8String:cppOpts->styleTemplate().c_str()];
        retVal.styleDomainName = [NSString stringWithUTF8String:cppOpts->styleDomainName().c_str()];
        retVal.styleVersionPrefix = cppOpts->styleVersionPrefix().has_value() ? [NSString stringWithUTF8String:cppOpts->styleVersionPrefix().value().c_str()] : nil;

        retVal.spritesTemplate = [NSString stringWithUTF8String:cppOpts->spritesTemplate().c_str()];
        retVal.spritesDomainName = [NSString stringWithUTF8String:cppOpts->spritesDomainName().c_str()];
        retVal.spritesVersionPrefix = cppOpts->styleVersionPrefix().has_value() ? [NSString stringWithUTF8String:cppOpts->spritesVersionPrefix().value().c_str()] : nil;

        retVal.glyphsTemplate = [NSString stringWithUTF8String:cppOpts->glyphsTemplate().c_str()];
        retVal.glyphsDomainName = [NSString stringWithUTF8String:cppOpts->glyphsDomainName().c_str()];
        retVal.glyphsVersionPrefix = cppOpts->styleVersionPrefix().has_value() ? [NSString stringWithUTF8String:cppOpts->glyphsVersionPrefix().value().c_str()] : nil;
 
        retVal.tileTemplate = [NSString stringWithUTF8String:cppOpts->tileTemplate().c_str()];
        retVal.tileDomainName = [NSString stringWithUTF8String:cppOpts->tileDomainName().c_str()];
        retVal.tileVersionPrefix = cppOpts->styleVersionPrefix().has_value() ? [NSString stringWithUTF8String:cppOpts->tileVersionPrefix().value().c_str()] : nil;
      
        std::vector<mbgl::util::DefaultStyle> cppDefaultStyles = cppOpts->defaultStyles();
        
        
        NSMutableArray<MHDefaultStyle*>* mglStyles = [[NSMutableArray<MHDefaultStyle*> alloc] init];
        for (auto it = begin(cppDefaultStyles); it != end(cppDefaultStyles); ++it) {
            NSString* url = [NSString stringWithUTF8String:it->getUrl().c_str()];
            
            auto* mglDefaultStyle = [[MHDefaultStyle alloc] init];
            mglDefaultStyle.url = [NSURL URLWithString:url];
            mglDefaultStyle.name = [NSString stringWithUTF8String:it->getName().c_str()];
            mglDefaultStyle.version = it->getCurrentVersion();
            [mglStyles addObject:mglDefaultStyle];
            
            // set default style name
            if (it->getName() == cppOpts->defaultStyle()) {
                retVal.defaultStyle = mglDefaultStyle;
            }
        }
        
        retVal.defaultStyles = mglStyles;
        return retVal;
    }
    
    return nil;

}

@end
