#import "MHImageSource.h"

#import "MHGeometry_Private.h"
#import "MHLoggingConfiguration_Private.h"
#import "MHSource_Private.h"
#import "MHTileSource_Private.h"
#import "NSURL+MHAdditions.h"
#if TARGET_OS_IPHONE
    #import "UIImage+MHAdditions.h"
#else
    #import "NSImage+MHAdditions.h"
#endif

#include <mbgl/style/sources/image_source.hpp>
#include <mbgl/util/premultiply.hpp>

@interface MHImageSource ()
- (instancetype)initWithIdentifier:(NSString *)identifier coordinateQuad:(MHCoordinateQuad)coordinateQuad NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) mbgl::style::ImageSource *rawSource;

@end

@implementation MHImageSource

- (instancetype)initWithIdentifier:(NSString *)identifier coordinateQuad:(MHCoordinateQuad)coordinateQuad {

    const auto coordsArray = MHLatLngArrayFromCoordinateQuad(coordinateQuad);
    auto source = std::make_unique<mbgl::style::ImageSource>(identifier.UTF8String, coordsArray);
    return self = [super initWithPendingSource:std::move(source)];
}


- (instancetype)initWithIdentifier:(NSString *)identifier coordinateQuad:(MHCoordinateQuad)coordinateQuad URL:(NSURL *)url {
    self =  [self initWithIdentifier:identifier coordinateQuad: coordinateQuad];
    self.URL = url;
    return self;
}


- (instancetype)initWithIdentifier:(NSString *)identifier coordinateQuad:(MHCoordinateQuad)coordinateQuad image:(MHImage *)image {
    self =  [self initWithIdentifier:identifier coordinateQuad: coordinateQuad];
    self.image = image;

    return self;
}

- (NSURL *)URL {
    MHAssertStyleSourceIsValid();
    auto url = self.rawSource->getURL();
    return url ? [NSURL URLWithString:@(url->c_str())] : nil;
}

- (void)setURL:(NSURL *)url {
    MHAssertStyleSourceIsValid();
    if (url) {
        self.rawSource->setURL(url.mgl_URLByStandardizingScheme.absoluteString.UTF8String);
        _image = nil;
    } else {
        self.image = nullptr;
    }
}

- (void)setImage:(MHImage *)image {
    MHAssertStyleSourceIsValid();
    if (image != nullptr) {
        self.rawSource->setImage(image.mgl_premultipliedImage);
    } else {
        self.rawSource->setImage(mbgl::PremultipliedImage({0,0}));
    }
    _image = image;
}

- (MHCoordinateQuad)coordinates {
    MHAssertStyleSourceIsValid();
    return MHCoordinateQuadFromLatLngArray(self.rawSource->getCoordinates());
}

- (void)setCoordinates: (MHCoordinateQuad)coordinateQuad {
    MHAssertStyleSourceIsValid();
    self.rawSource->setCoordinates(MHLatLngArrayFromCoordinateQuad(coordinateQuad));
}

- (NSString *)description {
    if (self.rawSource) {
        return [NSString stringWithFormat:@"<%@: %p; identifier = %@; coordinates = %@; URL = %@; image = %@>",
                NSStringFromClass([self class]), (void *)self, self.identifier,
                MHStringFromCoordinateQuad(self.coordinates),
                self.URL,
                self.image];
    }
    else {
        return [NSString stringWithFormat:@"<%@: %p; identifier = %@; coordinates = <unknown>; URL = <unknown>; image = %@>",
                NSStringFromClass([self class]), (void *)self, self.identifier, self.image];
    }
}

- (mbgl::style::ImageSource *)rawSource {
    return (mbgl::style::ImageSource *)super.rawSource;
}

- (NSString *)attributionHTMLString {
    if (!self.rawSource) {
        MHAssert(0, @"Source with identifier `%@` was invalidated after a style change", self.identifier);
        return nil;
    }

    auto attribution = self.rawSource->getAttribution();
    return attribution ? @(attribution->c_str()) : nil;
}

@end
