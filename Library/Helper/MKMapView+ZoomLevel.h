//
//  MKMapView+ZoomLevel.h
//  TinyRunner
//
//  Created by jason on 8/9/12.
//  Copyright (c) 2012 jason. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MKMapView (ZoomLevel)

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated;

- (void)zoomToFitOverlays; //Animation defaults to YES
- (void)zoomToFitOverlay:(id<MKOverlay>)anOverlay;
- (void)zoomToFitOverlays:(NSArray *)someOverlays;

- (void)zoomToFitOverlaysAnimated:(BOOL)animated;
- (void)zoomToFitOverlay:(id<MKOverlay>)anOverlay animated:(BOOL)animated;
- (void)zoomToFitOverlays:(NSArray *)someOverlays animated:(BOOL)animated;

- (void)zoomToFitOverlays:(NSArray *)someOverlays animated:(BOOL)animated insetProportion:(CGFloat)insetProportion; //inset 0->1, defaults in other methods to .1 (10%)

- (void)zoomToFitAnnotations;

- (void)zoomMapViewToFitPoints:(MKMapPoint *)points pointsCount:(int)count animated:(BOOL)animated;

@end
