//
//  MovementPath.h
//  TinyRunner
//
//  Created by jason on 8/7/12.
//  Copyright (c) 2012 jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <pthread.h>


@interface MovementPath : NSObject <NSCoding, MKOverlay>
{
    MKMapPoint *points;
    NSUInteger pointCount;
    NSUInteger pointSpace;
    
    MKMapRect boundingMapRect;
    
    pthread_rwlock_t rwLock;
}

@property (readonly) MKMapPoint *points;
@property (readonly) NSUInteger pointCount;
@property (readonly) CLLocationDistance distanceSoFar;

- (id)initWithCenterCoordinate:(CLLocationCoordinate2D)coord;

- (MKMapRect)addCoordinate:(CLLocationCoordinate2D)coord;

- (void)lockForReading;

- (void)unlockForReading;

- (NSString *)MKMapRectToNSString:(MKMapRect)mapRect;
- (MKMapRect)NSStringToMKMapRect:(NSString *)str;

@end
