#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 An object conforming to the ``MHOfflineRegion`` protocol determines which
 resources are required by an ``MHOfflinePack`` object.
 */
@protocol MHOfflineRegion <NSObject>

/**
 URL of the style whose resources are required for offline viewing.

 In addition to the JSON stylesheet, different styles may require different font
 glyphs, sprite sheets, and other resources.

 The URL may be a full HTTP or HTTPS URL or a canonical URL
 */
@property (nonatomic, readonly) NSURL *styleURL;

/**
 Specifies whether to include ideographic glyphs in downloaded font data.
 Ideographic glyphs make up the majority of downloaded font data, but
 it is possible to configure the renderer to use locally installed fonts
 instead of relying on fonts downloaded as part of the offline pack.
 See `MHIdeographicFontFamilyName` setting. Also, for regions outside of
 China, Japan, and Korea, these glyphs will rarely appear for non-CJK users.

 By default, this property is set to `NO`, so that the offline pack will
 include ideographic glyphs.
 */
@property (nonatomic) BOOL includesIdeographicGlyphs;

@end

NS_ASSUME_NONNULL_END
