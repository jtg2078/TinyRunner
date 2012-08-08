//
//  MovementPath.m
//  TinyRunner
//
//  Created by jason on 8/7/12.
//  Copyright (c) 2012 jason. All rights reserved.
//

#import "MovementPath.h"

@implementation MovementPath

#pragma mark - define

#define INITIAL_POINT_SPACE 1000
#define MINIMUM_DELTA_METERS 10.0

#pragma mark - synthesize

@synthesize points;
@synthesize pointCount;

#pragma mark - dealloc

- (void)dealloc
{
    free(points);
    pthread_rwlock_destroy(&rwLock);
    [super dealloc];
}

#pragma mark - init

- (id)initWithCenterCoordinate:(CLLocationCoordinate2D)coord
{
	self = [super init];
    if (self)
	{
        // initialize point storage and place this first coordinate in it
        pointSpace = INITIAL_POINT_SPACE;
        points = malloc(sizeof(MKMapPoint) * pointSpace);
        points[0] = MKMapPointForCoordinate(coord);
        pointCount = 1;
        
        // bite off up to 1/4 of the world to draw into.
        MKMapPoint origin = points[0];
        origin.x -= MKMapSizeWorld.width / 8.0;
        origin.y -= MKMapSizeWorld.height / 8.0;
        MKMapSize size = MKMapSizeWorld;
        size.width /= 4.0;
        size.height /= 4.0;
        boundingMapRect = (MKMapRect) { origin, size };
        MKMapRect worldRect = MKMapRectMake(0, 0, MKMapSizeWorld.width, MKMapSizeWorld.height);
        boundingMapRect = MKMapRectIntersection(boundingMapRect, worldRect);
        
        // initialize read-write lock for drawing and updates
        pthread_rwlock_init(&rwLock, NULL);
    }
    return self;
}

#pragma mark - MKOverlay

- (CLLocationCoordinate2D)coordinate
{
    return MKCoordinateForMapPoint(points[0]);
}

- (MKMapRect)boundingMapRect
{
    return boundingMapRect;
}

#pragma mark - thread safty

- (void)lockForReading
{
    pthread_rwlock_rdlock(&rwLock);
}

- (void)unlockForReading
{
    pthread_rwlock_unlock(&rwLock);
}

#pragma mark - main methods

- (MKMapRect)addCoordinate:(CLLocationCoordinate2D)coord
{
    // Acquire the write lock because we are going to be changing the list of points
    pthread_rwlock_wrlock(&rwLock);
    
    // Convert a CLLocationCoordinate2D to an MKMapPoint
    MKMapPoint newPoint = MKMapPointForCoordinate(coord);
    MKMapPoint prevPoint = points[pointCount - 1];
    
    // Get the distance between this new point and the previous point.
    CLLocationDistance metersApart = MKMetersBetweenMapPoints(newPoint, prevPoint);
    MKMapRect updateRect = MKMapRectNull;
    
    if (metersApart > MINIMUM_DELTA_METERS)
    {
        // Grow the points array if necessary
        if (pointSpace == pointCount)
        {
            pointSpace *= 2;
            points = realloc(points, sizeof(MKMapPoint) * pointSpace);
        }
        
        // Add the new point to the points array
        points[pointCount] = newPoint;
        pointCount++;
        
        // Compute MKMapRect bounding prevPoint and newPoint
        double minX = MIN(newPoint.x, prevPoint.x);
        double minY = MIN(newPoint.y, prevPoint.y);
        double maxX = MAX(newPoint.x, prevPoint.x);
        double maxY = MAX(newPoint.y, prevPoint.y);
        
        updateRect = MKMapRectMake(minX, minY, maxX - minX, maxY - minY);
    }
    
    pthread_rwlock_unlock(&rwLock);
    
    return updateRect;
}

@end
