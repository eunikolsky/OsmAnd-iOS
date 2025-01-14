//
//  OANavigationTypeViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 22.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OANavigationTypeViewController.h"
#import "OAIconTextTableViewCell.h"
#import "OAProfileDataObject.h"
#import "OAProfileNavigationSettingsViewController.h"
#import "OAApplicationMode.h"
#import "OAProfileDataUtils.h"
#import "OAAppSettings.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16

@implementation OANavigationTypeViewController
{
    NSArray<OARoutingProfileDataObject *> *_sortedRoutingProfiles;
    NSArray<NSString *> *_fileNames;
    NSArray<NSArray *> *_data;
}

#pragma mark - UIViewController

- (void) viewDidLoad
{
    [super viewDidLoad];

    [self setupTableHeaderViewWithText:OALocalizedString(@"select_nav_profile_dialog_message")];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"nav_type_hint");
}

#pragma mark - Table data

- (void)generateData
{
    _sortedRoutingProfiles = [OAProfileDataUtils getSortedRoutingProfiles];
    NSMutableArray *tableData = [NSMutableArray new];
    NSString *lastFileName = _sortedRoutingProfiles.firstObject.fileName;
    NSMutableArray *sectionData = [NSMutableArray new];
    NSMutableArray *fileNames = [NSMutableArray new];
    for (NSInteger i = 0; i < _sortedRoutingProfiles.count; i++)
    {
        OARoutingProfileDataObject *profile = _sortedRoutingProfiles[i];
        if ((lastFileName == nil && profile.fileName == nil) || [lastFileName isEqualToString:profile.fileName])
        {
            [sectionData addObject:@{
                @"type" : [OAIconTextTableViewCell getCellIdentifier],
                @"title" : profile.name,
                @"profile_ind" : @(i),
                @"icon" : profile.iconName,
            }];
        }
        else
        {
            [tableData addObject:[NSArray arrayWithArray:sectionData]];
            [sectionData removeAllObjects];
            lastFileName = profile.fileName;
            [fileNames addObject:lastFileName];
            [sectionData addObject:@{
                @"type" : [OAIconTextTableViewCell getCellIdentifier],
                @"title" : profile.name,
                @"profile_ind" : @(i),
                @"icon" : profile.iconName,
            }];
        }
    }
    [tableData addObject:[NSArray arrayWithArray:sectionData]];
    _fileNames = [NSArray arrayWithArray:fileNames];
    _data = [NSArray arrayWithArray:tableData];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    if (section == 0)
        return OALocalizedString(@"osmand_default_routing");
    else
        return _fileNames[section - 1].lastPathComponent;
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    if (section == [self.tableView numberOfSections] - 1)
        return OALocalizedString(@"import_routing_file_descr");
    else
        return @"";
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    OARoutingProfileDataObject *profile = _sortedRoutingProfiles[[item[@"profile_ind"] integerValue]];
    if ([cellType isEqualToString:[OAIconTextTableViewCell getCellIdentifier]])
    {
        OAIconTextTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            [cell.arrowIconView setHidden:YES];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.iconView.image = [UIImage templateImageNamed:item[@"icon"]];
            NSString *derivedProfile = self.appMode.getDerivedProfile;
            BOOL checkForDerived = ![derivedProfile isEqualToString:@"default"];
            BOOL isSelected = [profile.stringKey isEqual:self.appMode.getRoutingProfile] && ((!checkForDerived && !profile.derivedProfile) || (checkForDerived && [profile.derivedProfile isEqualToString:derivedProfile]));
            if (isSelected)
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.iconView.tintColor = isSelected ? UIColorFromRGB(self.appMode.getIconColor) : UIColorFromRGB(color_icon_inactive);
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
    OARoutingProfileDataObject *profileData = _sortedRoutingProfiles[[item[@"profile_ind"] integerValue]];
    if (profileData)
    {
        int routeService;
        if ([profileData.stringKey isEqualToString:@"STRAIGHT_LINE_MODE"])
            routeService = STRAIGHT;
        else if ([profileData.stringKey isEqualToString:@"DIRECT_TO_MODE"])
            routeService = DIRECT_TO;
//        else if (profileKey.equals(RoutingProfilesResources.BROUTER_MODE.name())) {
//            routeService = RouteProvider.RouteService.BROUTER;
        else
            routeService = OSMAND;
        
        NSString *derivedProfile = profileData.derivedProfile ? profileData.derivedProfile : @"default";
        [self.appMode setRoutingProfile:profileData.stringKey];
        [self.appMode setDerivedProfile:derivedProfile];
        [self.appMode setRouterService:routeService];
        if (self.delegate)
            [self.delegate onSettingsChanged];
        [self dismissViewController];
    }
}

#pragma mark - Selectors

- (void)onRotation
{
    [self setupTableHeaderViewWithText:OALocalizedString(@"select_nav_profile_dialog_message")];
}

@end
