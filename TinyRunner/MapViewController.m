//
//  MapViewController.m
//  TinyRunner
//
//  Created by jason on 8/7/12.
//  Copyright (c) 2012 jason. All rights reserved.
//

#import "MapViewController.h"
#import "SVProgressHUD.h"
#import "AppDelegate.h"

@interface MapViewController ()

@end

@implementation MapViewController

#pragma mark - define

#define LAST_SAVED_PATH     @"lastPath"

#pragma mark - synthesize

@synthesize myMapView;
@synthesize segControl;
@synthesize plotView;
@synthesize speedLabel;
@synthesize mPath;
@synthesize pathView;
@synthesize startPoint;
@synthesize endPoint;

#pragma mark - dealloc

- (void)dealloc
{
    [myMapView release];
    [segControl release];
    [mPath release];
    [pathView release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [plotView release];
    [speedLabel release];
    [startPoint release];
    [endPoint release];
    
    [super dealloc];
}

#pragma mark - init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // -------------------- navigation bar --------------------
    
    NSArray *itemArray = [NSArray arrayWithObjects:@"開始記錄", @"停止記錄", @"我的位置", @"記錄列表", nil];
    segControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segControl.frame = CGRectMake(0, 0, 250, 30);
    segControl.segmentedControlStyle = UISegmentedControlStyleBar;
    
    [segControl addTarget:self
                   action:@selector(segButtonPressed:)
         forControlEvents:UIControlEventValueChanged];
    
    self.navigationItem.titleView = segControl;
    
    // -------------------- notification --------------------
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self
               selector:@selector(handleLocationUpdate:)
                   name:UPDATE_LOCATION_NOTIF
                 object:nil];
    
    [center addObserver:self
               selector:@selector(handleLocationNotAvail:)
                   name:LOCATION_TRACKING_NOT_AVAIL_NOTIF
                 object:nil];
    
    [center addObserver:self
               selector:@selector(handleLocationUpdateError:)
                   name:ERROR_UPDATE_LOCATION_NOTIF
                 object:nil];
    
    // -------------------- speed plot --------------------
    
    plotView.capacity = 300;
    plotView.baselineValue = 0.0;
    plotView.lineColor = [UIColor redColor];
    plotView.showDot = YES;
    plotView.labelFormat = @"目前速度: %.02f m/s";
    plotView.label = self.speedLabel;
    
    // -------------------- map view --------------------
    
    myMapView.showsUserLocation = YES;
    
    // -------------------- misc --------------------
    
    manager = [AppManager sharedInstance];
}

- (void)viewDidUnload
{
    [self setMyMapView:nil];
    [self setSegControl:nil];
    [self setMPath:nil];
    [self setPathView:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self setPlotView:nil];
    [self setSpeedLabel:nil];
    [self setStartPoint:nil];
    [self setEndPoint:nil];
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - MKMapViewDelegate

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    if(self.pathView == nil)
    {
        self.pathView = [[[PathView alloc] initWithOverlay:overlay] autorelease];
    }
    
    return self.pathView;
}

#pragma mark - notification handling

- (void)handleLocationUpdate:(NSNotification *)notification
{
    CLLocation *newLocation = [notification.userInfo objectForKey:@"newLocation"];
    
    if (self.mPath == nil)
    {
        // This is the first time we're getting a location update,
        // so create the MovementPath and add it to the map.
        //
        self.mPath = [[[MovementPath alloc] initWithCenterCoordinate:newLocation.coordinate] autorelease];
        [self.myMapView addOverlay:self.mPath];
        
        // On the first location update only, zoom map to user location
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 2000, 2000);
        [self.myMapView setRegion:region animated:YES];
        
        [self configStartPoint:newLocation];
        [self configEndPoint:newLocation];
        
        [SVProgressHUD dismiss];
    }
    else
    {
        // This is a subsequent location update.
        // If the crumbs MKOverlay model object determines that the current location has moved
        // far enough from the previous location, use the returned updateRect to redraw just
        // the changed area.
        //
        MKMapRect updateRect = [self.mPath addCoordinate:newLocation.coordinate];
        
        if (!MKMapRectIsNull(updateRect))
        {
            // There is a non null update rect.
            // Compute the currently visible map zoom scale
            MKZoomScale currentZoomScale = (CGFloat)(self.myMapView.bounds.size.width / self.myMapView.visibleMapRect.size.width);
            // Find out the line width at this zoom scale and outset the updateRect by that amount
            CGFloat lineWidth = MKRoadWidthAtZoomScale(currentZoomScale);
            updateRect = MKMapRectInset(updateRect, -lineWidth, -lineWidth);
            // Ask the overlay view to update just the changed area.
            [self.pathView setNeedsDisplayInMapRect:updateRect];
        }
        
        [self configEndPoint:newLocation];
    }
    
    if(newLocation.speed >= 0.0)
        plotView.value = newLocation.speed;
}

- (void)handleLocationNotAvail:(NSNotification *)notification
{
    [SVProgressHUD showErrorWithStatus:@"無法定位:("];
}

- (void)handleLocationUpdateError:(NSNotification *)notification
{
    [SVProgressHUD showErrorWithStatus:@"Error occured:("];
}

#pragma mark - user interaction

- (void)segButtonPressed:(id)sender
{
    // @"開始記錄", @"停止記錄", @"我的位置", @"記錄列表"
    switch (((UISegmentedControl *)sender).selectedSegmentIndex)
    {
        case 0:
        {
            [SVProgressHUD showWithStatus:@"定位中..."];
            
            [self clearCurrentPath];
            
            [manager startTracking];
            break;
        }
        case 1:
        {
            [SVProgressHUD dismiss]; // just in case
            [manager stopTracking];
            [self saveCurrentPath];
            break;
        }
        case 2:
        {
            /*
            CLLocation *location = manager.locationManager.location;
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000);
            [self.myMapView setRegion:region animated:YES];
             */
            [self clearCurrentPath];
            break;
        }
        case 3:
        {
            [self loadLastSavedPath];
            break;
        }
        default:
        {
            break;
        }
    }
}

#pragma mark - misc

- (void)configStartPoint:(CLLocation *)location
{
    MyAnnotation *anno = [[MyAnnotation alloc] init];
    anno.name = @"起點";
    anno.date = location.timestamp;
    anno.dateString = [manager.dateFormatter stringFromDate:anno.date];
    anno.lat = [NSNumber numberWithDouble:location.coordinate.latitude];
    anno.lng = [NSNumber numberWithDouble:location.coordinate.longitude];
    
    self.startPoint = anno;
    [anno release];
}

- (void)configEndPoint:(CLLocation *)location
{
    MyAnnotation *anno = [[MyAnnotation alloc] init];
    anno.name = @"終點";
    anno.date = location.timestamp;
    anno.dateString = [manager.dateFormatter stringFromDate:anno.date];
    anno.lat = [NSNumber numberWithDouble:location.coordinate.latitude];
    anno.lng = [NSNumber numberWithDouble:location.coordinate.longitude];
    
    self.endPoint = anno;
    [anno release];
}

- (void)clearCurrentPath
{
    if(self.mPath)
        [self.myMapView removeOverlay:self.mPath];
    
    self.mPath = nil;
    self.pathView = nil;
    
    if(self.startPoint)
    {
        [self.myMapView removeAnnotation:self.startPoint];
        self.startPoint = nil;
    }
    
    if(self.endPoint)
    {
        [self.myMapView removeAnnotation:self.endPoint];
        self.endPoint = nil;
    }
    
    [plotView clear];
}

- (void)saveCurrentPath
{
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filename = [docsPath stringByAppendingPathComponent:LAST_SAVED_PATH];
    if([NSKeyedArchiver archiveRootObject:self.mPath toFile:filename] == YES)
    {
        [SVProgressHUD showSuccessWithStatus:@"儲存成功"];
    }
    else
    {
        [SVProgressHUD showErrorWithStatus:@"儲存失敗"];
    }
    
    Track *t = [manager createTrack];
    t.name = [manager.dateFormatter stringFromDate:self.startPoint.date];
    t.note = @"";
    t.startDate = self.startPoint.date;
    t.startLat = self.startPoint.lat;
    t.startLon = self.startPoint.lng;
    t.endDate = self.endPoint.date;
    t.endLat = self.endPoint.lat;
    t.endLon = self.endPoint.lng;
    t.totalDistance = [NSNumber numberWithDouble:self.mPath.distanceSoFar];
    t.averageSpeed = [NSNumber numberWithDouble:
                      (t.totalDistance.doubleValue / [t.endDate timeIntervalSinceDate:t.startDate])];
    t.note = @"";
    
    t.trackData = [NSKeyedArchiver archivedDataWithRootObject:self.mPath];
    t.speedData = [NSKeyedArchiver archivedDataWithRootObject:plotView.data];
    
    [manager save];
}

- (void)loadLastSavedPath
{
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filename = [docsPath stringByAppendingPathComponent:LAST_SAVED_PATH];
    MovementPath *aPath = [NSKeyedUnarchiver unarchiveObjectWithFile:filename];
    
    if(aPath == nil)
    {
        [SVProgressHUD showErrorWithStatus:@"讀取失敗"];
        return;
    }
    else
    {
        [SVProgressHUD showSuccessWithStatus:@"讀取成功"];
    }
    
    [self loadPath:aPath];
}

- (void)loadPath:(MovementPath *)aPath
{
    [self clearCurrentPath];
    
    self.mPath = aPath;
    [self.myMapView addOverlay:self.mPath];
    [self.myMapView setNeedsDisplay];
}

@end
