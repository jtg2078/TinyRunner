//
//  SavedViewController.h
//  TinyRunner
//
//  Created by jason on 8/9/12.
//  Copyright (c) 2012 jason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@interface SavedViewController : BaseViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>
{
    
}

@property (retain, nonatomic) IBOutlet UITableView *myTableView;
@property (retain, nonatomic) NSFetchedResultsController *frc;

@end
