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
@synthesize distanceSoFar;

#pragma mark - dealloc

- (void)dealloc
{
    free(points);
    pthread_rwlock_destroy(&rwLock);
    [super dealloc];
}

#pragma mark - init

- (id)initWithCoder:(NSCoder *)coder {
	self = [super init];
	if (self != nil) {
        
        NSArray *pts = (NSArray *)[coder decodeObjectForKey:@"points"];
        
        pointSpace = pts.count;
        pointCount = pts.count;
        points = malloc(sizeof(MKMapPoint) * pointSpace);
        
        int i = 0;
        for(NSArray *ptInfo in pts)
        {
            NSNumber *x = [ptInfo objectAtIndex:0];
            NSNumber *y = [ptInfo objectAtIndex:1];
            MKMapPoint pt = MKMapPointMake(x.doubleValue, y.doubleValue);
            points[i] = pt;
            i++;
        }
        
        NSString *string = [coder decodeObjectForKey:@"boundingMapRect"];
        boundingMapRect = [self NSStringToMKMapRect:string];
        //boundingMapRect = [self adjustBoundingMapRect];
        
        NSNumber *dist = [coder decodeObjectForKey:@"distanceSoFar"];
        distanceSoFar = dist.doubleValue;
        
        // initialize read-write lock for drawing and updates
        pthread_rwlock_init(&rwLock, NULL);
	}
	return self;
}

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
        
        distanceSoFar = 0;
        
        // initialize read-write lock for drawing and updates
        pthread_rwlock_init(&rwLock, NULL);
    }
    return self;
}

#pragma mark - NSCoder

- (void)encodeWithCoder:(NSCoder *)coder
{
    NSMutableArray *pts = [NSMutableArray arrayWithCapacity:pointCount];
    
    for(int i = 0; i< pointCount; i++)
    {
        MKMapPoint pt = points[i];
        NSArray *ptInfo = [NSArray arrayWithObjects:
                           [NSNumber numberWithDouble:pt.x],
                           [NSNumber numberWithDouble:pt.y], nil];
        [pts addObject:ptInfo];
    }
    [coder encodeObject:pts             forKey:@"points"];
    
    NSString *string = [self MKMapRectToNSString:boundingMapRect];
    [coder encodeObject:string          forKey:@"boundingMapRect"];
    
    NSNumber *dist = [NSNumber numberWithDouble:distanceSoFar];
    [coder encodeObject:dist            forKey:@"distanceSoFar"];
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
        
        distanceSoFar += metersApart;
    }
    
    pthread_rwlock_unlock(&rwLock);
    
    return updateRect;
}

#pragma mark - helper

- (NSString *)MKMapRectToNSString:(MKMapRect)mapRect
{
    CGRect rect;
    rect.origin.x = mapRect.origin.x;
    rect.origin.y = mapRect.origin.y;
    rect.size.width = mapRect.size.width;
    rect.size.height = mapRect.size.height;
    return NSStringFromCGRect(rect);
}

- (MKMapRect)NSStringToMKMapRect:(NSString *)str
{
    MKMapRect mapRect;
    CGRect rect = CGRectFromString(str);
    mapRect.origin.x = rect.origin.x;
    mapRect.origin.y = rect.origin.y;
    mapRect.size.width = rect.size.width;
    mapRect.size.height = rect.size.height;
    return mapRect;
}

- (MKMapRect)adjustBoundingMapRect
{
    MKMapPoint pt = points[pointCount - 1];
    MKMapRect zoomRect = MKMapRectMake(pt.x, pt.y, 0, 0);
    
    for(int i = 0; i< pointCount; i++)
    {
        pt = points[i];
        
        MKMapRect pointRect = MKMapRectMake(pt.x, pt.y, 0, 0);
        
        if (MKMapRectIsNull(zoomRect))
        {
            zoomRect = pointRect;
        }
        else
        {
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
    }
    
    return zoomRect;
}

@end
