//
//  OACloudAccountLogoutViewController.mm
//  OsmAnd
//
//  Created by Skalii on 21.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OACloudAccountLogoutViewController.h"
#import "OAIconTitleValueCell.h"
#import "OAAppSettings.h"
#import "OAColors.h"
#import "Localization.h"

@implementation OACloudAccountLogoutViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"login_account");
}

#pragma mark - Table data

- (void)generateData
{
    _data = @[
            @[@{
                    @"key": @"user_cell",
                    @"type": [OAIconTitleValueCell getCellIdentifier],
                    @"title": [[OAAppSettings sharedManager].backupUserEmail get],
                    @"icon": @"ic_custom_user_profile"
            }],
            @[@{
                    @"key": @"logout_cell",
                    @"type": [OAIconTitleValueCell getCellIdentifier],
                    @"title": OALocalizedString(@"shared_string_logout")
            }]
    ];
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    UITableViewCell *outCell = nil;

    if ([item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];
            [cell showRightIcon:NO];
        }
        if (cell)
        {
            BOOL isLogoutCell = [item[@"key"] isEqualToString:@"logout_cell"];
            cell.selectionStyle = isLogoutCell ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            [cell showLeftIcon:!isLogoutCell];
            cell.textView.font = [UIFont scaledSystemFontOfSize:17. weight:isLogoutCell ? UIFontWeightMedium : UIFontWeightRegular];
            cell.textView.text = item[@"title"];
            cell.textView.textColor = isLogoutCell ? UIColorFromRGB(color_support_red) : UIColor.blackColor;
            cell.textView.textAlignment = isLogoutCell ? NSTextAlignmentCenter : NSTextAlignmentNatural;
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
            cell.leftIconView.tintColor = UIColorFromRGB(color_icon_color);
            cell.descriptionView.text = @"";
        }
        outCell = cell;
    }

    [outCell updateConstraintsIfNeeded];
    return outCell;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowPressed:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"key"] isEqualToString:@"logout_cell"])
    {

        UIAlertController *alert =
                [UIAlertController alertControllerWithTitle:OALocalizedString(@"shared_string_logout")
                                                    message:OALocalizedString(@"logout_from_osmand_cloud_decsr")
                                             preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil
        ];

        UIAlertAction *logoutAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_logout")
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action)
                                                                 {

                                                                     if (self.logoutDelegate)
                                                                         [self.logoutDelegate onLogout];

                                                                     [self dismissViewController];
                                                                 }
        ];

        [alert addAction:cancelAction];
        [alert addAction:logoutAction];

        alert.preferredAction = logoutAction;

        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
