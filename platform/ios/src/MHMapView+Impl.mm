#import "MHMapView+Impl.h"
#import "MHMapView_Private.h"
#import "MHStyle_Private.h"
#import "NSBundle+MHAdditions.h"

#if MH_RENDER_BACKEND_METAL
#import "MHMapView+Metal.h"
#else // MH_RENDER_BACKEND_OPENGL
#import "MHMapView+OpenGL.h"
#endif

std::unique_ptr<MHMapViewImpl> MHMapViewImpl::Create(MHMapView* nativeView) {
#if MH_RENDER_BACKEND_METAL
    return std::make_unique<MHMapViewMetalImpl>(nativeView);
#else // MH_RENDER_BACKEND_OPENGL
    return std::make_unique<MHMapViewOpenGLImpl>(nativeView);
#endif
}

MHMapViewImpl::MHMapViewImpl(MHMapView* nativeView_) : mapView(nativeView_) {
}

void MHMapViewImpl::render() {
    [mapView renderSync];
}

void MHMapViewImpl::onCameraWillChange(mbgl::MapObserver::CameraChangeMode mode) {
    bool animated = mode == mbgl::MapObserver::CameraChangeMode::Animated;
    [mapView cameraWillChangeAnimated:animated];
}

void MHMapViewImpl::onCameraIsChanging() {
    [mapView cameraIsChanging];
}

void MHMapViewImpl::onCameraDidChange(mbgl::MapObserver::CameraChangeMode mode) {
    bool animated = mode == mbgl::MapObserver::CameraChangeMode::Animated;
    [mapView cameraDidChangeAnimated:animated];
}

void MHMapViewImpl::onWillStartLoadingMap() {
    [mapView mapViewWillStartLoadingMap];
}

void MHMapViewImpl::onDidFinishLoadingMap() {
    [mapView mapViewDidFinishLoadingMap];
}

void MHMapViewImpl::onDidFailLoadingMap(mbgl::MapLoadError mapError, const std::string& what) {
    NSString *description;
    MHErrorCode code;
    switch (mapError) {
        case mbgl::MapLoadError::StyleParseError:
            code = MHErrorCodeParseStyleFailed;
            description = NSLocalizedStringWithDefaultValue(@"PARSE_STYLE_FAILED_DESC", nil, nil, @"The map failed to load because the style is corrupted.", @"User-friendly error description");
            break;
        case mbgl::MapLoadError::StyleLoadError:
            code = MHErrorCodeLoadStyleFailed;
            description = NSLocalizedStringWithDefaultValue(@"LOAD_STYLE_FAILED_DESC", nil, nil, @"The map failed to load because the style can’t be loaded.", @"User-friendly error description");
            break;
        case mbgl::MapLoadError::NotFoundError:
            code = MHErrorCodeNotFound;
            description = NSLocalizedStringWithDefaultValue(@"STYLE_NOT_FOUND_DESC", nil, nil, @"The map failed to load because the style can’t be found or is incompatible.", @"User-friendly error description");
            break;
        default:
            code = MHErrorCodeUnknown;
            description = NSLocalizedStringWithDefaultValue(@"LOAD_MAP_FAILED_DESC", nil, nil, @"The map failed to load because an unknown error occurred.", @"User-friendly error description");
    }
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: description,
        NSLocalizedFailureReasonErrorKey: @(what.c_str()),
    };
    NSError *error = [NSError errorWithDomain:MHErrorDomain code:code userInfo:userInfo];

    [mapView mapViewDidFailLoadingMapWithError:error];
}

void MHMapViewImpl::onWillStartRenderingFrame() {
    [mapView mapViewWillStartRenderingFrame];
}

void MHMapViewImpl::onDidFinishRenderingFrame(const mbgl::MapObserver::RenderFrameStatus& status) {
    const bool fullyRendered = status.mode == mbgl::MapObserver::RenderMode::Full;
    [mapView mapViewDidFinishRenderingFrameFullyRendered:fullyRendered renderingStats:status.renderingStats];
}

void MHMapViewImpl::onWillStartRenderingMap() {
    [mapView mapViewWillStartRenderingMap];
}

void MHMapViewImpl::onDidFinishRenderingMap(mbgl::MapObserver::RenderMode mode) {
    bool fullyRendered = mode == mbgl::MapObserver::RenderMode::Full;
    [mapView mapViewDidFinishRenderingMapFullyRendered:fullyRendered];
}

void MHMapViewImpl::onDidFinishLoadingStyle() {
    [mapView mapViewDidFinishLoadingStyle];
}

void MHMapViewImpl::onSourceChanged(mbgl::style::Source& source) {
    NSString *identifier = @(source.getID().c_str());
    MHSource * nativeSource = [mapView.style sourceWithIdentifier:identifier];
    [mapView sourceDidChange:nativeSource];
}

void MHMapViewImpl::onDidBecomeIdle() {
    [mapView mapViewDidBecomeIdle];
}

void MHMapViewImpl::onStyleImageMissing(const std::string& imageIdentifier) {
    NSString *imageName = [NSString stringWithUTF8String:imageIdentifier.c_str()];
    [mapView didFailToLoadImage:imageName];
}

bool MHMapViewImpl::onCanRemoveUnusedStyleImage(const std::string &imageIdentifier) {
    NSString *imageName = [NSString stringWithUTF8String:imageIdentifier.c_str()];
    return [mapView shouldRemoveStyleImage:imageName];
}

void MHMapViewImpl::onRegisterShaders(mbgl::gfx::ShaderRegistry& shaders) {

}

void MHMapViewImpl::onPreCompileShader(mbgl::shaders::BuiltIn shaderID, mbgl::gfx::Backend::Type backend, const std::string& defines) {
    NSString *definesCopy = [NSString stringWithUTF8String:defines.c_str()];
    [mapView shaderWillCompile:static_cast<int>(shaderID) backend:static_cast<int>(backend) defines:definesCopy];
}

void MHMapViewImpl::onPostCompileShader(mbgl::shaders::BuiltIn shaderID, mbgl::gfx::Backend::Type backend, const std::string& defines) {
    NSString *definesCopy = [NSString stringWithUTF8String:defines.c_str()];
    [mapView shaderDidCompile:static_cast<int>(shaderID) backend:static_cast<int>(backend) defines:definesCopy];
}

void MHMapViewImpl::onShaderCompileFailed(mbgl::shaders::BuiltIn shaderID, mbgl::gfx::Backend::Type backend, const std::string& defines) {
    NSString *definesCopy = [NSString stringWithUTF8String:defines.c_str()];
    [mapView shaderDidFailCompile:static_cast<int>(shaderID) backend:static_cast<int>(backend) defines:definesCopy];
}

void MHMapViewImpl::onGlyphsLoaded(const mbgl::FontStack& fontStack, const mbgl::GlyphRange& range) {
    NSMutableArray* fontStackCopy = [[NSMutableArray alloc] init];
    std::for_each(fontStack.begin(), fontStack.end(), ^(const std::string& str) {
        [fontStackCopy addObject:[NSString stringWithUTF8String:str.c_str()]];
    });

    [mapView glyphsDidLoad:fontStackCopy range:NSMakeRange(range.first, range.second - range.first)];
}

void MHMapViewImpl::onGlyphsError(const mbgl::FontStack& fontStack, const mbgl::GlyphRange& range, std::exception_ptr error) {
    NSMutableArray* fontStackCopy = [[NSMutableArray alloc] init];
    std::for_each(fontStack.begin(), fontStack.end(), ^(const std::string& str) {
        [fontStackCopy addObject:[NSString stringWithUTF8String:str.c_str()]];
    });

    [mapView glyphsDidError:fontStackCopy range:NSMakeRange(range.first, range.second - range.first)];
}

void MHMapViewImpl::onGlyphsRequested(const mbgl::FontStack& fontStack, const mbgl::GlyphRange& range) {
    NSMutableArray* fontStackCopy = [[NSMutableArray alloc] init];
    std::for_each(fontStack.begin(), fontStack.end(), ^(const std::string& str) {
        [fontStackCopy addObject:[NSString stringWithUTF8String:str.c_str()]];
    });

    [mapView glyphsWillLoad:fontStackCopy range:NSMakeRange(range.first, range.second - range.first)];
}

void MHMapViewImpl::onTileAction(mbgl::TileOperation operation, const mbgl::OverscaledTileID& tile, const std::string& sourceID) {
    [mapView tileDidTriggerAction:MHTileOperation(static_cast<int>(operation))
                                x:tile.canonical.x
                                y:tile.canonical.y
                                z:tile.canonical.z
                             wrap:tile.wrap
                      overscaledZ:tile.overscaledZ
                         sourceID:[NSString stringWithUTF8String:sourceID.c_str()]];
}

void MHMapViewImpl::onSpriteLoaded(const std::optional<mbgl::style::Sprite>& spriteID) {
    if (!spriteID.has_value()) {
        [mapView spriteDidLoad:nil url:nil];
        return;
    }

    [mapView spriteDidLoad:[NSString stringWithUTF8String:spriteID.value().id.c_str()]
                       url:[NSString stringWithUTF8String:spriteID.value().spriteURL.c_str()]];
}

void MHMapViewImpl::onSpriteError(const std::optional<mbgl::style::Sprite>& spriteID, std::exception_ptr error) {
    if (!spriteID.has_value()) {
        [mapView spriteDidError:nil url:nil];
        return;
    }

    [mapView spriteDidError:[NSString stringWithUTF8String:spriteID.value().id.c_str()]
                        url:[NSString stringWithUTF8String:spriteID.value().spriteURL.c_str()]];
}

void MHMapViewImpl::onSpriteRequested(const std::optional<mbgl::style::Sprite>& spriteID) {
    if (!spriteID.has_value()) {
        [mapView spriteWillLoad:nil url:nil];
        return;
    }

    [mapView spriteWillLoad:[NSString stringWithUTF8String:spriteID.value().id.c_str()]
                        url:[NSString stringWithUTF8String:spriteID.value().spriteURL.c_str()]];
}
