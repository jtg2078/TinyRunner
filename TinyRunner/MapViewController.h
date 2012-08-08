//
//  MapViewController.h
//  TinyRunner
//
//  Created by jason on 8/7/12.
//  Copyright (c) 2012 jason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "AppManager.h"
#import "MovementPath.h"
#import "PathView.h"
#import "F3PlotStrip.h"

@interface MapViewController : UIViewController <MKMapViewDelegate>
{
    AppManager *manager;
}

@property (retain, nonatomic) IBOutlet MKMapView *myMapView;
@property (retain, nonatomic) UISegmentedControl *segControl;
@property (retain, nonatomic) IBOutlet F3PlotStrip *plotView;
@property (retain, nonatomic) IBOutlet UILabel *speedLabel;

@property (retain, nonatomic) MovementPath *mPath;
@property (retain, nonatomic) PathView *pathView;


@end
