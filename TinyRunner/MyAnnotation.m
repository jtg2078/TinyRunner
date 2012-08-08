//
//  MyAnnotation.m
//  TinyRunner
//
//  Created by jason on 8/8/12.
//  Copyright (c) 2012 jason. All rights reserved.
//

#import "MyAnnotation.h"

@implementation MyAnnotation

#pragma mark - synthesize

@synthesize name;
@synthesize dateString;
@synthesize lat;
@synthesize lng;
@synthesize date;

#pragma mark - dealloc

- (void)dealloc
{
    [name release];
    [dateString release];
    [lat release];
    [lng release];
    [date release];
    
    [super dealloc];
}

#pragma mark - MKAnnotation

- (CLLocationCoordinate2D)coordinate;
{
    CLLocationCoordinate2D theCoordinate;
    theCoordinate.latitude = lat.doubleValue;
    theCoordinate.longitude = lng.doubleValue;
    return theCoordinate;
}

- (NSString *)title
{
    return self.name;
}

- (NSString *)subtitle
{
    return self.dateString;
}

@end
