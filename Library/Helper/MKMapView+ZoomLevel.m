//
//  MKMapView+ZoomLevel.m
//  TinyRunner
//
//  Created by jason on 8/9/12.
//  Copyright (c) 2012 jason. All rights reserved.
//

#import "MKMapView+ZoomLevel.h"

#define MERCATOR_OFFSET 268435456
#define MERCATOR_RADIUS 85445659.44705395

@implementation MKMapView (ZoomLevel)

#pragma mark -
#pragma mark Map conversion methods

- (double)longitudeToPixelSpaceX:(double)longitude
{
    return round(MERCATOR_OFFSET + MERCATOR_RADIUS * longitude * M_PI / 180.0);
}

- (double)latitudeToPixelSpaceY:(double)latitude
{
    return round(MERCATOR_OFFSET - MERCATOR_RADIUS * logf((1 + sinf(latitude * M_PI / 180.0)) / (1 - sinf(latitude * M_PI / 180.0))) / 2.0);
}

- (double)pixelSpaceXToLongitude:(double)pixelX
{
    return ((round(pixelX) - MERCATOR_OFFSET) / MERCATOR_RADIUS) * 180.0 / M_PI;
}

- (double)pixelSpaceYToLatitude:(double)pixelY
{
    return (M_PI / 2.0 - 2.0 * atan(exp((round(pixelY) - MERCATOR_OFFSET) / MERCATOR_RADIUS))) * 180.0 / M_PI;
}

#pragma mark -
#pragma mark Helper methods

- (MKCoordinateSpan)coordinateSpanWithMapView:(MKMapView *)mapView
							 centerCoordinate:(CLLocationCoordinate2D)centerCoordinate
								 andZoomLevel:(NSUInteger)zoomLevel
{
    // convert center coordiate to pixel space
    double centerPixelX = [self longitudeToPixelSpaceX:centerCoordinate.longitude];
    double centerPixelY = [self latitudeToPixelSpaceY:centerCoordinate.latitude];
    
    // determine the scale value from the zoom level
    NSInteger zoomExponent = 20 - zoomLevel;
    double zoomScale = pow(2, zoomExponent);
    
    // scale the map’s size in pixel space
    CGSize mapSizeInPixels = mapView.bounds.size;
    double scaledMapWidth = mapSizeInPixels.width * zoomScale;
    double scaledMapHeight = mapSizeInPixels.height * zoomScale;
    
    // figure out the position of the top-left pixel
    double topLeftPixelX = centerPixelX - (scaledMapWidth / 2);
    double topLeftPixelY = centerPixelY - (scaledMapHeight / 2);
    
    // find delta between left and right longitudes
    CLLocationDegrees minLng = [self pixelSpaceXToLongitude:topLeftPixelX];
    CLLocationDegrees maxLng = [self pixelSpaceXToLongitude:topLeftPixelX + scaledMapWidth];
    CLLocationDegrees longitudeDelta = maxLng - minLng;
    
    // find delta between top and bottom latitudes
    CLLocationDegrees minLat = [self pixelSpaceYToLatitude:topLeftPixelY];
    CLLocationDegrees maxLat = [self pixelSpaceYToLatitude:topLeftPixelY + scaledMapHeight];
    CLLocationDegrees latitudeDelta = -1 * (maxLat - minLat);
    
    // create and return the lat/lng span
    MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    return span;
}

#pragma mark -
#pragma mark Public methods

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
				  zoomLevel:(NSUInteger)zoomLevel
				   animated:(BOOL)animated
{
    // clamp large numbers to 28
    zoomLevel = MIN(zoomLevel, 28);
    
    // use the zoom level to compute the region
    MKCoordinateSpan span = [self coordinateSpanWithMapView:self centerCoordinate:centerCoordinate andZoomLevel:zoomLevel];
    MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
    
    // set the region like normal
    [self setRegion:region animated:animated];
}

#pragma mark -
#pragma mark Zoom to Fit

- (void)zoomToFitOverlays {
    [self zoomToFitOverlaysAnimated:YES];
}

- (void)zoomToFitOverlay:(id<MKOverlay>)anOverlay {
    [self zoomToFitOverlay:[NSArray arrayWithObject:anOverlay] animated:YES];
}

- (void)zoomToFitOverlays:(NSArray *)someOverlays {
    [self zoomToFitOverlays:someOverlays animated:YES];
}

- (void)zoomToFitOverlaysAnimated:(BOOL)animated {
    [self zoomToFitOverlays:self.overlays animated:animated];
}

- (void)zoomToFitOverlay:(id<MKOverlay>)anOverlay animated:(BOOL)animated {
    [self zoomToFitOverlays:[NSArray arrayWithObject:anOverlay] animated:YES];
}

- (void)zoomToFitOverlays:(NSArray *)someOverlays animated:(BOOL)animated {
    [self zoomToFitOverlays:someOverlays animated:animated insetProportion:.1];
}

- (void)zoomToFitOverlays:(NSArray *)someOverlays animated:(BOOL)animated insetProportion:(CGFloat)insetProportion {
    //Check
    if ( !someOverlays || !someOverlays.count ) {
        return;
    }
    
    //Union
    MKMapRect mapRect = MKMapRectNull;
    if ( someOverlays.count == 1 ) {
        mapRect = ((id<MKOverlay>)someOverlays.lastObject).boundingMapRect;
    } else {
        for ( id<MKOverlay> anOverlay in someOverlays ) {
            mapRect = MKMapRectUnion(mapRect, anOverlay.boundingMapRect);
        }
    }
    
    //Inset
    CGFloat inset = (CGFloat)(mapRect.size.width*insetProportion);
    mapRect = [self mapRectThatFits:MKMapRectInset(mapRect, inset, inset)];
    
    //Set
    MKCoordinateRegion region = MKCoordinateRegionForMapRect(mapRect);
    [self setRegion:region animated:animated];
}

- (void)zoomToFitAnnotations {
    
    NSArray *coordinates = [self valueForKeyPath:@"annotations.coordinate"];

    CLLocationCoordinate2D maxCoord = {-90.0f, -180.0f};
    CLLocationCoordinate2D minCoord = {90.0f, 180.0f};
    
    for(NSValue *value in coordinates) {
        
        CLLocationCoordinate2D coord = {0.0f, 0.0f};
        [value getValue:&coord];
        
        if(coord.longitude > maxCoord.longitude) {
            maxCoord.longitude = coord.longitude;
        }
        
        if(coord.latitude > maxCoord.latitude) {
            maxCoord.latitude = coord.latitude;
        }
        
        if(coord.longitude < minCoord.longitude) {
            minCoord.longitude = coord.longitude;
        }
        
        if(coord.latitude < minCoord.latitude) {
            minCoord.latitude = coord.latitude;
        }
        
    }
    
    MKCoordinateRegion region = {{0.0f, 0.0f}, {0.0f, 0.0f}};
    region.center.longitude = (minCoord.longitude + maxCoord.longitude) / 2.0;
    region.center.latitude = (minCoord.latitude + maxCoord.latitude) / 2.0;
    region.span.longitudeDelta = maxCoord.longitude - minCoord.longitude;
    region.span.latitudeDelta = maxCoord.latitude - minCoord.latitude;
    
    [self setRegion:region animated:YES];
}

#define MINIMUM_ZOOM_ARC 0.007 
// 0.014 = approximately 1 miles (1 degree of arc ~= 69 miles)
#define ANNOTATION_REGION_PAD_FACTOR 1.15
#define MAX_DEGREES_ARC 360

- (void)zoomMapViewToFitPoints:(MKMapPoint *)points pointsCount:(int)count animated:(BOOL)animated
{
    //create MKMapRect from array of MKMapPoint
    MKMapRect mapRect = [[MKPolygon polygonWithPoints:points count:count] boundingMapRect];
    
    //convert MKCoordinateRegion from MKMapRect
    MKCoordinateRegion region = MKCoordinateRegionForMapRect(mapRect);
    
    //add padding so pins aren't scrunched on the edges
    region.span.latitudeDelta  *= ANNOTATION_REGION_PAD_FACTOR;
    region.span.longitudeDelta *= ANNOTATION_REGION_PAD_FACTOR;
    
    //but padding can't be bigger than the world
    if(region.span.latitudeDelta > MAX_DEGREES_ARC)
        region.span.latitudeDelta  = MAX_DEGREES_ARC;
    
    if(region.span.longitudeDelta > MAX_DEGREES_ARC)
        region.span.longitudeDelta = MAX_DEGREES_ARC;
    
    //and don't zoom in stupid-close on small samples
    if(region.span.latitudeDelta < MINIMUM_ZOOM_ARC)
        region.span.latitudeDelta  = MINIMUM_ZOOM_ARC;
    
    if(region.span.longitudeDelta < MINIMUM_ZOOM_ARC)
        region.span.longitudeDelta = MINIMUM_ZOOM_ARC;
    
    //and if there is a sample of 1 we want the max zoom-in instead of max zoom-out
    if( count == 1 )
    {
        region.span.latitudeDelta = MINIMUM_ZOOM_ARC;
        region.span.longitudeDelta = MINIMUM_ZOOM_ARC;
    }
    
    [self setRegion:region animated:animated];
}

@end
