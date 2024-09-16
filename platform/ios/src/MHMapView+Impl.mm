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

void MHMapViewImpl::onDidFinishRenderingFrame(mbgl::MapObserver::RenderFrameStatus status) {
    bool fullyRendered = status.mode == mbgl::MapObserver::RenderMode::Full;
    [mapView mapViewDidFinishRenderingFrameFullyRendered:fullyRendered frameEncodingTime:status.frameEncodingTime frameRenderingTime:status.frameRenderingTime];
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
