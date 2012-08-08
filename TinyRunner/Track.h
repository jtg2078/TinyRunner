//
//  Track.h
//  TinyRunner
//
//  Created by jason on 8/8/12.
//  Copyright (c) 2012 jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Track : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSNumber * startLat;
@property (nonatomic, retain) NSNumber * startLon;
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSNumber * endLat;
@property (nonatomic, retain) NSNumber * endLon;
@property (nonatomic, retain) NSNumber * totalDistance;
@property (nonatomic, retain) NSNumber * averageSpeed;
@property (nonatomic, retain) NSString * note;
@property (nonatomic, retain) NSData * trackData;
@property (nonatomic, retain) NSData * speedData;

@end
