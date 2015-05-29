//
//  OAParkingViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAParkingViewController.h"
#import "Localization.h"
#import "OASwitchTableViewCell.h"
#import "OADateTimePickerTableViewCell.h"
#import "OATimeTableViewCell.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OANativeUtilities.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

@interface OAParkingViewController ()

@end

@implementation OAParkingViewController
{
    NSDateFormatter *_timeFmt;
}

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate
{
    self = [super init];
    if (self) {
        _coord = coordinate;
        _timeLimitActive = NO;
        _addToCalActive = YES;
        _timeFmt = [[NSDateFormatter alloc] init];
        [_timeFmt setDateStyle:NSDateFormatterNoStyle];
        [_timeFmt setTimeStyle:NSDateFormatterShortStyle];
        _date = [self dateNoSec:[NSDate dateWithTimeIntervalSinceNow:60 * 60]];
    }
    return self;
}

- (NSDate *)dateNoSec:(NSDate *)date
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents *dateComponents = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit
                                                   fromDate:date];
    [dateComponents setSecond:0];
    
    return [calendar dateFromComponents:dateComponents];
}

- (CGFloat)contentHeight
{
    return (_timeLimitActive ? 44.0 * 3.0 + 162.0 : 44.0) + 34.0 + 16.0;
}

- (void)applyLocalization
{
    [self.buttonCancel setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.buttonOK setTitle:OALocalizedString(@"shared_string_add") forState:UIControlStateNormal];
    self.titleView.text = OALocalizedString(@"parking_marker");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)hasTopToolbar
{
    return YES;
}

- (void)okPressed
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(addParking:)])
        [self.delegate addParking:self];
}

- (void)cancelPressed
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(cancelParking:)])
        [self.delegate cancelParking:self];
}

- (void)setContentBackgroundColor:(UIColor *)color
{
    [super setContentBackgroundColor:color];
    _tableView.backgroundColor = color;
}

-(void)timeLimitSwitched:(id)sender
{
    _timeLimitActive = ((UISwitch*)sender).isOn;
    [_tableView beginUpdates];
    
    NSArray *paths = @[
                       [NSIndexPath indexPathForRow:1 inSection:0],
                       [NSIndexPath indexPathForRow:2 inSection:0],
                       [NSIndexPath indexPathForRow:3 inSection:0]];
    
    if (_timeLimitActive)
        [_tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationBottom];
    else
        [_tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
    
    [_tableView endUpdates];
    
    if (self.heightChangeListenerBlock)
        self.heightChangeListenerBlock([self contentHeight]);
}

-(void)timePickerChanged:(id)sender
{
    UIDatePicker *picker = (UIDatePicker *)sender;
    _date = [self dateNoSec:picker.date];
    if (_timeLimitActive)
        [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

-(void)addNotificationSwitched:(id)sender
{
    _addToCalActive = ((UISwitch*)sender).isOn;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return OALocalizedString(@"sett_settings");
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_timeLimitActive)
        return 4;
    else
        return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString* const reusableIdentifierSwitch = @"OASwitchTableViewCell";
    static NSString* const reusableIdentifierTimePicker = @"OADateTimePickerTableViewCell";
    static NSString* const reusableIdentifierTime = @"OATimeTableViewCell";
    
    switch (indexPath.row)
    {
        case 0:
        {
            OASwitchTableViewCell* cell;
            cell = (OASwitchTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierSwitch];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
                cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            }
            [cell.switchView setOn:_timeLimitActive];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(timeLimitSwitched:) forControlEvents:UIControlEventValueChanged];
            
            cell.textView.text = OALocalizedString(@"time_limited");
            
            return cell;
        }
        case 1:
        {
            OATimeTableViewCell* cell;
            cell = (OATimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierTime];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATimeCell" owner:self options:nil];
                cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.lbTitle.text = OALocalizedString(@"pickup_car_at");
            cell.lbTime.text = [_timeFmt stringFromDate:_date];
            
            return cell;
        }
        case 2:
        {
            OADateTimePickerTableViewCell* cell;
            cell = (OADateTimePickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierTimePicker];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OADateTimePickerCell" owner:self options:nil];
                cell = (OADateTimePickerTableViewCell *)[nib objectAtIndex:0];
                cell.dateTimePicker.date = _date;
            }
            
            [cell.dateTimePicker removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.dateTimePicker addTarget:self action:@selector(timePickerChanged:) forControlEvents:UIControlEventValueChanged];
            
            return cell;
        }
        case 3:
        {
            OASwitchTableViewCell* cell;
            cell = (OASwitchTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierSwitch];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
                cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            }
            
            [cell.switchView setOn:_addToCalActive];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(addNotificationSwitched:) forControlEvents:UIControlEventValueChanged];
            
            cell.textView.text = OALocalizedString(@"add_notification_calendar");
            
            return cell;
        }
            
        default:
            break;
    }
    
    return nil;
}



#pragma mark - UITableViewDelegate

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 34.0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 16.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 2)
        return 162.0;
    else
        return 44.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}


@end
