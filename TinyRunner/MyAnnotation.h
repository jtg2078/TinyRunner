//
//  MyAnnotation.h
//  TinyRunner
//
//  Created by jason on 8/8/12.
//  Copyright (c) 2012 jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MyAnnotation : NSObject <MKAnnotation>
{
    
}

@property (strong, nonatomic) NSString * name;
@property (strong, nonatomic) NSString * dateString;
@property (strong, nonatomic) NSDate   * date;
@property (strong, nonatomic) NSNumber * lat;
@property (strong, nonatomic) NSNumber * lng;

@end
