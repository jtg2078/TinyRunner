//
//  SavedViewController.m
//  TinyRunner
//
//  Created by jason on 8/9/12.
//  Copyright (c) 2012 jason. All rights reserved.
//

#import "SavedViewController.h"
#import "Track.h"

@interface SavedViewController ()

@end

@implementation SavedViewController

#pragma mark - define

#pragma mark - synthesize

@synthesize myTableView;
@synthesize frc;

#pragma mark - dealloc

- (void)dealloc
{
    [myTableView release];
    [frc release];
    
    [super dealloc];
}

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
    
    // -------------------- naivgation bar --------------------
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"返回", nil)
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = leftButton;
    
    // -------------------- data --------------------
    
    [self loadData];
}

- (void)viewDidUnload
{
    [self setMyTableView:nil];
    self.frc.delegate = nil;
    [self setFrc:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    int count = [[self.frc sections] count];
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.frc sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
        cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Track *t = [self.frc objectAtIndexPath:indexPath];
    
    NSDictionary *info = [NSDictionary dictionaryWithObject:t.objectID forKey:@"objectID"];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:LOAD_SAVED_TRACK_NOTIF object:nil userInfo:info];
    
    [self.appDelegate dismissModalViewControllerAnimated:YES];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.myTableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.myTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                            withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.myTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                            withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    
    UITableView *tableView = self.myTableView;
    
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath]
                    atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.myTableView endUpdates];
}

#pragma mark - configure cell

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Track *t = [self.frc objectAtIndexPath:indexPath];
    cell.textLabel.text = [self.manager.dateFormatter stringFromDate:t.startDate];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"距離: %.02f 公尺 平均速度: %0.2f 公尺/秒", t.totalDistance.doubleValue, t.averageSpeed.doubleValue];
}

#pragma mark - load data

- (void)loadData
{
    // setup fetch request
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Track" inManagedObjectContext:self.context];
	[fetchRequest setEntity:entity];
	
	// setup sorting
    NSSortDescriptor *sort1 = [[[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:NO] autorelease];
	[fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sort1, nil]];
	[fetchRequest setFetchBatchSize:20];
	
	// setup fetched result controller
	NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																				 managedObjectContext:self.context
																				   sectionNameKeyPath:nil
																							cacheName:nil];
	controller.delegate = self;
	self.frc = controller;
	[fetchRequest release];
	[controller release];
	
	NSError *error;
	if (![self.frc performFetch:&error])
    {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
	else
    {
		// load the table
		[self.myTableView reloadData];
	}
}

#pragma mark - user interaction

- (void)dismiss
{
    [self.appDelegate dismissModalViewControllerAnimated:YES];
}

@end
