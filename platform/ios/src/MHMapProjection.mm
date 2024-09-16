#include <mbgl/map/map.hpp>
#include <mbgl/map/map_projection.hpp>
#include <mbgl/util/geo.hpp>
#include <mbgl/util/projection.hpp>

#import "MHMapProjection.h"
#import "MHMapView_Private.h"
#import "MHGeometry_Private.h"

@interface MHMapProjection ()

@property (nonatomic) CGSize mapFrameSize;

@end

@implementation MHMapProjection
{
    std::unique_ptr<mbgl::MapProjection> _mbglProjection;
}

- (instancetype)initWithMapView:(MHMapView *)mapView
{
    if (self = [super init])
    {
        _mbglProjection = std::make_unique<mbgl::MapProjection>([mapView mbglMap]);
        self.mapFrameSize = mapView.frame.size;
    }
    return self;
}

- (MHMapCamera*)camera
{
    mbgl::CameraOptions cameraOptions = _mbglProjection->getCamera();

    CLLocationCoordinate2D centerCoordinate = MHLocationCoordinate2DFromLatLng(*cameraOptions.center);
    double zoomLevel = *cameraOptions.zoom;
    CLLocationDirection direction = mbgl::util::wrap(*cameraOptions.bearing, 0., 360.);
    CGFloat pitch = *cameraOptions.pitch;
    CLLocationDistance altitude = MHAltitudeForZoomLevel(zoomLevel, pitch,
                                                          centerCoordinate.latitude, self.mapFrameSize);
    return [MHMapCamera cameraLookingAtCenterCoordinate:centerCoordinate altitude:altitude
                                                   pitch:pitch heading:direction];
}

- (void)setCamera:(MHMapCamera * _Nonnull)camera withEdgeInsets:(UIEdgeInsets)insets
{
    mbgl::CameraOptions cameraOptions;
    if (CLLocationCoordinate2DIsValid(camera.centerCoordinate))
    {
        cameraOptions.center = MHLatLngFromLocationCoordinate2D(camera.centerCoordinate);
    }
    cameraOptions.padding = MHEdgeInsetsFromNSEdgeInsets(insets);
    cameraOptions.zoom = MHZoomLevelForAltitude(camera.altitude, camera.pitch,
                                                 camera.centerCoordinate.latitude,
                                                 self.mapFrameSize);
    if (camera.heading >= 0)
    {
        cameraOptions.bearing = camera.heading;
    }
    if (camera.pitch >= 0)
    {
        cameraOptions.pitch = camera.pitch;
    }

    _mbglProjection->setCamera(cameraOptions);
}

- (void)setVisibleCoordinateBounds:(MHCoordinateBounds)bounds edgePadding:(UIEdgeInsets)insets {
    CLLocationCoordinate2D coordinates[] = {
        {bounds.ne.latitude, bounds.sw.longitude},
        bounds.sw,
        {bounds.sw.latitude, bounds.ne.longitude},
        bounds.ne,
    };

    mbgl::EdgeInsets padding = MHEdgeInsetsFromNSEdgeInsets(insets);
    std::vector<mbgl::LatLng> latLngs;
    latLngs.reserve(4);
    for (NSUInteger i = 0; i < 4; i++)
    {
        latLngs.push_back({coordinates[i].latitude, coordinates[i].longitude});
    }

    _mbglProjection->setVisibleCoordinates(latLngs, padding);
}

- (CLLocationCoordinate2D)convertPoint:(CGPoint)point
{
    mbgl::ScreenCoordinate screenCoordinate = mbgl::ScreenCoordinate(point.x, point.y);
    return MHLocationCoordinate2DFromLatLng(_mbglProjection->latLngForPixel(screenCoordinate).wrapped());
}

- (CGPoint)convertCoordinate:(CLLocationCoordinate2D)coordinate
{
    if ( !CLLocationCoordinate2DIsValid(coordinate))
    {
        return CGPointMake(NAN, NAN);
    }

    mbgl::LatLng latLng = MHLatLngFromLocationCoordinate2D(coordinate);
    mbgl::ScreenCoordinate pixel = _mbglProjection->pixelForLatLng(latLng);
    return CGPointMake(pixel.x, pixel.y);
}

- (CLLocationDistance)metersPerPoint
{
    mbgl::CameraOptions cameraOptions = _mbglProjection->getCamera();
    return mbgl::Projection::getMetersPerPixelAtLatitude(cameraOptions.center->latitude(),
                                                         *cameraOptions.zoom);
}


@end
