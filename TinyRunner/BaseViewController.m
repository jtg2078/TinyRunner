//
//  BaseViewController.m
//  TinyRunner
//
//  Created by jason on 8/9/12.
//  Copyright (c) 2012 jason. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

@synthesize manager;
@synthesize context;
@synthesize appDelegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.manager = [AppManager sharedInstance];
    self.appDelegate = [UIApplication sharedApplication].delegate;
    self.context = self.appDelegate.managedObjectContext;
}

- (void)viewDidUnload
{
    self.manager = nil;
    self.appDelegate = nil;
    self.context = nil;
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
