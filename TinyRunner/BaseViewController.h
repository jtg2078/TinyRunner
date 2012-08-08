//
//  BaseViewController.h
//  TinyRunner
//
//  Created by jason on 8/9/12.
//  Copyright (c) 2012 jason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppManager.h"
#import "AppDelegate.h"


@interface BaseViewController : UIViewController
{
    
}

@property (nonatomic, assign) AppManager *manager;
@property (nonatomic, assign) NSManagedObjectContext *context;
@property (nonatomic, assign) AppDelegate *appDelegate;

@end
