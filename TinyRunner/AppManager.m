//
//  AppManager.m
//  TinyRunner
//
//  Created by jason on 8/7/12.
//  Copyright (c) 2012 jason. All rights reserved.
//

#import "AppManager.h"
#import "AppDelegate.h"

NSString * const UPDATE_LOCATION_NOTIF = @"UPDATE_LOCATION_NOTIF";
NSString * const LOCATION_TRACKING_NOT_AVAIL_NOTIF = @"LOCATION_TRACKING_NOT_AVAIL_NOTIF";
NSString * const ERROR_UPDATE_LOCATION_NOTIF = @"ERROR_UPDATE_LOCATION_NOTIF";

@implementation AppManager

#pragma mark - define

#pragma mark - synthesize

@synthesize locationManager;
@synthesize useHighAccuracyMode;
@synthesize context;
@synthesize dateFormatter;

- (NSManagedObjectContext *)context
{
    if(context == nil)
    {
        AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        context = [delegate.managedObjectContext retain];
    }
    return context;
}

#pragma dealloc

- (void)dealloc
{
    [locationManager release];
    [context release];
    [dateFormatter release];
    [super dealloc];
}

#pragma mark - init and setup

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    center = [NSNotificationCenter defaultCenter];
    
    useHighAccuracyMode = NO;
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    [dateFormatter setDateFormat:@"MM-dd HH:mm:ss"];
}

#pragma mark - gps methods

- (void)startTracking
{
    if([CLLocationManager locationServicesEnabled] == NO)
    {
        [center postNotificationName:LOCATION_TRACKING_NOT_AVAIL_NOTIF object:self];
    }
    
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
}

- (void)stopTracking
{
    [locationManager stopUpdatingLocation];
    locationManager.delegate = nil;
}

#pragma mark - core data method

- (Track *)createTrack
{
    Track *track = [NSEntityDescription insertNewObjectForEntityForName:@"Track"
                                                 inManagedObjectContext:self.context];
    return track;
}

- (NSError *)save
{
    NSError *error = nil;
    [self.context save:&error];
    
    return error;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    // -------------------- filters for better accuracy --------------------
    
    if(self.useHighAccuracyMode == YES)
    {
        // Filter out nil locations
        if (!newLocation) return;
        
        // Filter out points by invalid accuracy
        if (newLocation.horizontalAccuracy < 0) return;
        if (newLocation.horizontalAccuracy > 66) return;
        
        // Filter out points by invalid accuracy
#if !TARGET_IPHONE_SIMULATOR
        if (newLocation.verticalAccuracy < 0) return;
#endif
        
        // Filter out points that are out of order
        NSTimeInterval secondsSinceLastPoint = [newLocation.timestamp timeIntervalSinceDate:oldLocation.timestamp];
        if (secondsSinceLastPoint < 0) return;
        
        // Make sure the update is new not cached
        NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
        if (locationAge > 5.0) return;
        
        // Check to see if old and new are the same
        if ((oldLocation.coordinate.latitude == newLocation.coordinate.latitude) && (oldLocation.coordinate.longitude == newLocation.coordinate.longitude))
            return;
    }
    
    // ----------------------------------------------------------------------
    
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          newLocation, @"newLocation",
                          oldLocation, @"oldLocation",
                          nil];
    
    [center postNotificationName:UPDATE_LOCATION_NOTIF object:self userInfo:info];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSDictionary *info = [NSDictionary dictionaryWithObject:error forKey:@"error"];
    
    [center postNotificationName:ERROR_UPDATE_LOCATION_NOTIF object:self userInfo:info];
}

#pragma mark - singleton implementation code

static AppManager *singletonManager = nil;

+ (AppManager *)sharedInstance {
    
    static dispatch_once_t pred;
    static AppManager *manager;
    
    dispatch_once(&pred, ^{
        manager = [[self alloc] init];
    });
    return manager;
}
+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (singletonManager == nil) {
            singletonManager = [super allocWithZone:zone];
            return singletonManager;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}
- (id)copyWithZone:(NSZone *)zone {
    return self;
}
- (id)retain {
    return self;
}
- (unsigned)retainCount {
    return UINT_MAX;  // denotes an object that cannot be released
}
- (oneway void)release {
    //do nothing
}
- (id)autorelease {
    return self;
}

@end
