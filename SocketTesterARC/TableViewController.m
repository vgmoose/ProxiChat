//
//  TableViewController.m
//  Lists
//
//  Created by Philip Donlon on 11/17/14.
//  Copyright (c) 2014 Philip Donlon. All rights reserved.
//

#import "TableViewController.h"

@interface TableViewController ()

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleObjectsArray = @[@"iPhone 6",
                               @"iPhone 5S",
                               @"iPhone 5",
                               @"iPhone 4S",
                               @"iPhone 4",];
    
    self.subtitleObjectsArray = @[@"2014",
                               @"2013",
                               @"2012",
                               @"2011",
                               @"2010",];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.titleObjectsArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    cell.textLabel.text = [self.titleObjectsArray objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = [self.subtitleObjectsArray objectAtIndex:indexPath.row];
    
    return cell;
}
@end
