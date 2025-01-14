//
//  OAEditGroupViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAEditGroupViewController.h"
#import "OAIconTextTableViewCell.h"
#import "OAInputTableViewCell.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#include "Localization.h"

@implementation OAEditGroupViewController
{
    NSArray* _groups;
}

-(id)initWithGroupName:(NSString *)groupName groups:(NSArray *)groups
{
    self = [super init];
    if (self) {
        self.groupName = groupName;
        _groups = [groups sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
            return [obj1 localizedCaseInsensitiveCompare:obj2];
        }];
    }
    return self;
}

- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"shared_string_groups");
    [_saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _saveChanges = NO;
    
    [self setupView];
    self.saveButton.titleLabel.font = [UIFont scaledSystemFontOfSize:14.];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

-(void)setupView
{
    [self applySafeAreaMargins];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [@[OALocalizedString(@"shared_string_groups"), OALocalizedString(@"fav_create_group")] objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return [_groups count] + 1;
    else
        return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        OAIconTextTableViewCell* cell;
        cell = (OAIconTextTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            if (indexPath.row > 0)
            {
                NSString* item = [_groups objectAtIndex:indexPath.row - 1];
                [cell showImage:NO];
                [cell.textView setText:item];
                [cell.arrowIconView setImage:nil];
                if ([item isEqualToString:self.groupName])
                    [cell.arrowIconView setImage:[UIImage imageNamed:@"menu_cell_selected"]];
            }
            else
            {
                [cell showImage:NO];
                [cell.textView setText:OALocalizedString(@"favorites_item")];
                [cell.arrowIconView setImage:nil];
                if (self.groupName.length == 0)
                    [cell.arrowIconView setImage:[UIImage imageNamed:@"menu_cell_selected"]];
            }
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
        }
        return cell;
    }
    else
    {
        OAInputTableViewCell *cell = (OAInputTableViewCell *) [tableView dequeueReusableCellWithIdentifier:[OAInputTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAInputTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAInputTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell titleVisibility:NO];
            [cell clearButtonVisibility:NO];
            cell.inputField.textAlignment = NSTextAlignmentNatural;
            cell.inputField.placeholder = OALocalizedString(@"fav_enter_group_name");
        }
        if (cell)
        {
            cell.inputField.delegate = self;
            [cell.inputField removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
            [cell.inputField addTarget:self action:@selector(editGroupName:) forControlEvents:UIControlEventEditingChanged];
        }
        return cell;
    }
    return nil;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        if (indexPath.row == 0)
            self.groupName = @"";
        else
            self.groupName = [_groups objectAtIndex:indexPath.row - 1];
        
        [self.tableView reloadData];
    }
    else
    {
        [self.tableView reloadData];
    }
}

#pragma mark - UITextFieldDelegate
- (void)editGroupName:(id)sender
{
    self.groupName = [((UITextField*)sender) text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}


#pragma mark - Actions

- (IBAction)saveClicked:(id)sender
{
    _saveChanges = YES;

    if (self.delegate && [self.delegate respondsToSelector:@selector(groupChanged)])
        [self.delegate groupChanged];

    [self dismissViewController];
}

@end
