//
//  OAProfileNavigationSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 22.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileNavigationSettingsViewController.h"
#import "OAIconTitleValueCell.h"
#import "OAIconTextTableViewCell.h"
#import "OASettingsTitleTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OANavigationTypeViewController.h"
#import "OARouteParametersViewController.h"
#import "OAVoicePromptsViewController.h"
#import "OAScreenAlertsViewController.h"
#import "OAVehicleParametersViewController.h"
#import "OAMapBehaviorViewController.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"
#import "OAProfileDataObject.h"
#import "OsmAndApp.h"
#import "OAProfileDataUtils.h"
#import "OARootViewController.h"
#import "OARouteLineAppearanceHudViewController.h"
#import "OAMainSettingsViewController.h"
#import "OAConfigureProfileViewController.h"

#import "Localization.h"
#import "OAColors.h"

#define kOsmAndNavigation @"osmand_navigation"

@interface OAProfileNavigationSettingsViewController () <OARouteLineAppearanceViewControllerDelegate>

@end

@implementation OAProfileNavigationSettingsViewController
{
    NSArray<NSArray *> *_data;
    
    OAAppSettings *_settings;
    
    NSDictionary<NSString *, OARoutingProfileDataObject *> *_routingProfileDataObjects;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"routing_settings_2");
}

#pragma mark - Table data

- (void)generateData
{
    NSString *selectedProfileName = self.appMode.getRoutingProfile;
    _routingProfileDataObjects = [OAProfileDataUtils getRoutingProfiles];
    NSArray *profiles = [_routingProfileDataObjects allValues];
    OARoutingProfileDataObject *routingData;
    NSString *derivedProfile = self.appMode.getDerivedProfile;
    BOOL checkForDerived = ![derivedProfile isEqualToString:@"default"];
    for (OARoutingProfileDataObject *profile in profiles)
    {
        if([profile.stringKey isEqual:selectedProfileName])
        {
            if ((!checkForDerived && !profile.derivedProfile) || (checkForDerived && [profile.derivedProfile isEqualToString:derivedProfile]))
            {
                routingData = profile;
                break;
            }
        }
    }
    
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *navigationArr = [NSMutableArray array];
    NSMutableArray *otherArr = [NSMutableArray array];
    [navigationArr addObject:@{
        @"type" : [OAIconTitleValueCell getCellIdentifier],
        @"title" : OALocalizedString(@"nav_type_hint"),
        @"value" : routingData ? routingData.name : @"",
        @"icon" : routingData ? routingData.iconName : @"ic_custom_navigation",
        @"key" : @"navigationType",
    }];
    [navigationArr addObject:@{
        @"type" : [OAIconTextTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"route_parameters"),
        @"icon" : @"ic_custom_route",
        @"key" : @"routeParams",
    }];
    [navigationArr addObject:@{
        @"type" : [OAIconTextTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"voice_announces"),
        @"icon" : @"ic_custom_sound",
        @"key" : @"voicePrompts",
    }];
    [navigationArr addObject:@{
        @"type" : [OAIconTextTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"screen_alerts"),
        @"icon" : @"ic_custom_alert",
        @"key" : @"screenAlerts",
    }];
    [navigationArr addObject:@{
        @"type" : [OAIconTextTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"vehicle_parameters"),
        @"icon" : self.appMode.getIconName,
        @"key" : @"vehicleParams",
    }];
    [navigationArr addObject:@{
        @"type" : [OAIconTextTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"customize_route_line"),
        @"icon" : @"ic_custom_appearance",
        @"key" : @"routeLineAppearance",
    }];
    [otherArr addObject:@{
        @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"map_during_navigation"),
        @"key" : @"mapBehavior",
    }];
    [tableData addObject:navigationArr];
    [tableData addObject:otherArr];
    [tableData addObject:@[@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"animate_my_location")
    }]];
    
    _data = [NSArray arrayWithArray:tableData];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return OALocalizedString(@"routing_settings");
        case 1:
            return OALocalizedString(@"other_location");
        default:
            return @"";
    }
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    switch (section)
    {
        case 1:
            return OALocalizedString(@"change_map_behavior");
        case 2:
            return OALocalizedString(@"animate_my_location_descr");
        default:
            return @"";
    }
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            cell.rightIconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.leftIconView.tintColor = UIColorFromRGB(color_icon_inactive);
            cell.descriptionView.textColor = UIColorFromRGB(color_text_footer);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAIconTextTableViewCell getCellIdentifier]])
    {
        OAIconTextTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.arrowIconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            cell.arrowIconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.iconView.image = [UIImage templateImageNamed:item[@"icon"]];
            cell.iconView.tintColor = UIColorFromRGB(color_icon_inactive);
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];

            cell.switchView.on = [_settings.animateMyLocation get:self.appMode];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASettingsTitleTableViewCell getCellIdentifier]])
    {
        OASettingsTitleTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTitleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.iconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowPressed:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *itemKey = item[@"key"];
    if ([itemKey isEqualToString:@"routeLineAppearance"])
    {
        if (self.openFromRouteInfo)
        {
            [self dismissViewControllerAnimated:YES completion:^{
                if (self.delegate)
                    [self.delegate closeSettingsScreenWithRouteInfo];
            }];
        }
        else
        {
            [self.navigationController popToViewController:OARootViewController.instance animated:YES];
        }
        OARouteLineAppearanceHudViewController *routeLineAppearanceHudViewController =
                [[OARouteLineAppearanceHudViewController alloc] initWithAppMode:self.appMode];
        routeLineAppearanceHudViewController.delegate = self;
        [OARootViewController.instance.mapPanel showScrollableHudViewController:routeLineAppearanceHudViewController];
    }
    else
    {
        OABaseSettingsViewController *settingsViewController = nil;
        if ([itemKey isEqualToString:@"navigationType"])
            settingsViewController = [[OANavigationTypeViewController alloc] initWithAppMode:self.appMode];
        else if ([itemKey isEqualToString:@"routeParams"])
            settingsViewController = [[OARouteParametersViewController alloc] initWithAppMode:self.appMode];
        else if ([itemKey isEqualToString:@"voicePrompts"])
            settingsViewController = [[OAVoicePromptsViewController alloc] initWithAppMode:self.appMode];
        else if ([itemKey isEqualToString:@"screenAlerts"])
            settingsViewController = [[OAScreenAlertsViewController alloc] initWithAppMode:self.appMode];
        else if ([itemKey isEqualToString:@"vehicleParams"])
            settingsViewController = [[OAVehicleParametersViewController alloc] initWithAppMode:self.appMode];
        else if ([itemKey isEqualToString:@"mapBehavior"])
            settingsViewController = [[OAMapBehaviorViewController alloc] initWithAppMode:self.appMode];
        if (settingsViewController)
        {
            settingsViewController.delegate = self;
            [self showViewController:settingsViewController];
        }
    }
}

#pragma mark - Selectors

- (void)applyParameter:(UISwitch *)sender
{
    [_settings.animateMyLocation set:sender.isOn mode:self.appMode];
}

#pragma mark - OASettingsDataDelegate

- (void)onSettingsChanged
{
    [self generateData];
    [super onSettingsChanged];
    if (self.delegate)
        [self.delegate onSettingsChanged];
}

#pragma mark - OARouteLineAppearanceViewControllerDelegate

- (void)onCloseAppearance
{
    if (self.openFromRouteInfo)
    {
        [[OARootViewController instance].mapPanel showRouteInfo];
        [[OARootViewController instance].mapPanel showRoutePreferences];
    }
    else
    {
        OAMainSettingsViewController *settingsVC = [[OAMainSettingsViewController alloc] initWithTargetAppMode:self.appMode
                                                                                               targetScreenKey:kNavigationSettings];
        [OARootViewController.instance.navigationController pushViewController:settingsVC animated:NO];
    }
}

@end
