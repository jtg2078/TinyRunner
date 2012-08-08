//
//  AppManager.h
//  TinyRunner
//
//  Created by jason on 8/7/12.
//  Copyright (c) 2012 jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

extern NSString * const UPDATE_LOCATION_NOTIF;
extern NSString * const LOCATION_TRACKING_NOT_AVAIL_NOTIF;
extern NSString * const ERROR_UPDATE_LOCATION_NOTIF;

@interface AppManager : NSObject <CLLocationManagerDelegate>
{
    NSNotificationCenter *center;
}

@property (retain, nonatomic) CLLocationManager *locationManager;

+ (AppManager *)sharedInstance;

- (void)startTracking;
- (void)stopTracking;

@end
