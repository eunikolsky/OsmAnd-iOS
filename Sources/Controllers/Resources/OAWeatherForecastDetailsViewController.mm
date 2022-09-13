//
//  OAWeatherForecastDetailsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 05.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherForecastDetailsViewController.h"
#import "OAWeatherCacheSettingsViewController.h"
#import "OAWeatherFrequencySettingsViewController.h"
#import "OACustomBasicTableCell.h"
#import "MBProgressHUD.h"
#import "OATableViewCustomHeaderView.h"
#import "OAResourcesUIHelper.h"
#import "OAWeatherHelper.h"
#import "OASizes.h"
#import "OAColors.h"
#import "Localization.h"

@interface OAWeatherForecastDetailsViewController  () <UITableViewDelegate, UITableViewDataSource, OAWeatherCacheSettingsDelegate, OAWeatherFrequencySettingsDelegate>

@property (weak, nonatomic) IBOutlet UIView *viewNavigationSeparator;

@end

@implementation OAWeatherForecastDetailsViewController
{
    OAWeatherHelper *_weatherHelper;
    OAWorldRegion *_region;
    NSMutableArray<NSMutableArray<NSMutableDictionary *> *> *_data;
    NSMapTable<NSNumber *, NSString *> *_headers;
    NSMapTable<NSNumber *, NSString *> *_footers;
    NSString *_accuracyDescription;

    MBProgressHUD *_progressHUD;
    NSIndexPath *_sizeIndexPath;
    NSIndexPath *_updateNowIndexPath;
    BOOL _isHeaderBlurred;

    OAAutoObserverProxy *_weatherSizeCalculatedObserver;
    OAAutoObserverProxy *_weatherForecastDownloadingObserver;
}

- (instancetype)initWithRegion:(OAWorldRegion *)region
{
    self = [super init];
    if (self)
    {
        _region = region;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _weatherHelper = [OAWeatherHelper sharedInstance];
    _weatherSizeCalculatedObserver =
            [[OAAutoObserverProxy alloc] initWith:self
                                      withHandler:@selector(onWeatherSizeCalculated:withKey:andValue:)
                                       andObserve:[OAWeatherHelper sharedInstance].weatherSizeCalculatedObserver];
    _weatherForecastDownloadingObserver =
            [[OAAutoObserverProxy alloc] initWith:self
                                      withHandler:@selector(onWeatherForecastDownloading:withKey:andValue:)
                                       andObserve:[OAWeatherHelper sharedInstance].weatherForecastDownloadingObserver];
    _headers = [NSMapTable new];
    _footers = [NSMapTable new];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.backButton.hidden = YES;
    self.backImageButton.hidden = NO;

    self.titleLabel.text = _region.name;

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];

    [self setupView];

    _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_progressHUD];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_weatherHelper calculateCacheSize:_region onComplete:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (_weatherSizeCalculatedObserver)
    {
        [_weatherSizeCalculatedObserver detach];
        _weatherSizeCalculatedObserver = nil;
    }
    if (_weatherForecastDownloadingObserver)
    {
        [_weatherForecastDownloadingObserver detach];
        _weatherForecastDownloadingObserver = nil;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (@available(iOS 13.0, *))
        return UIStatusBarStyleDarkContent;

    return UIStatusBarStyleDefault;
}

- (NSString *)getTableHeaderTitle
{
    return _region.name;
}

- (void) setTableHeaderView:(NSString *)label
{
    UIView *headerView = [OAUtilities setupTableHeaderViewWithText:label
                                                              font:[UIFont systemFontOfSize:34.0 weight:UIFontWeightBold]
                                                         textColor:UIColor.blackColor
                                                       lineSpacing:0.0
                                                           isTitle:YES];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(
        0.,
        headerView.layer.frame.size.height + 7.,
        DeviceScreenWidth,
        1.
    )];
    separator.backgroundColor = UIColorFromRGB(color_tint_gray);
    [headerView addSubview:separator];

    CGRect frame = headerView.frame;
    frame.size.height += 8.;
    headerView.frame = frame;
    
    self.tableView.tableHeaderView = headerView;
}

- (void)setupView
{
    NSMutableArray<NSMutableArray<NSMutableDictionary *> *> *data = [NSMutableArray array];

    NSMutableArray<NSMutableDictionary *> *infoCells = [NSMutableArray array];
    [data addObject:infoCells];

    _accuracyDescription = [OAWeatherHelper getAccuracyDescription:_region.regionId];
    [_headers setObject:_accuracyDescription forKey:@([data indexOfObject:infoCells])];

    NSMutableDictionary *updatedData = [NSMutableDictionary dictionary];
    updatedData[@"key"] = @"updated_cell";
    updatedData[@"type"] = [OACustomBasicTableCell getCellIdentifier];
    updatedData[@"title"] = OALocalizedString(@"shared_string_updated");
    updatedData[@"value"] = [OAWeatherHelper getUpdatesDateFormat:_region.regionId next:NO];
    updatedData[@"value_color"] = UIColor.blackColor;
    updatedData[@"selection_style"] = @(UITableViewCellSelectionStyleNone);
    [infoCells addObject:updatedData];

    NSMutableDictionary *nextUpdateData = [NSMutableDictionary dictionary];
    nextUpdateData[@"key"] = @"next_update_cell";
    nextUpdateData[@"type"] = [OACustomBasicTableCell getCellIdentifier];
    nextUpdateData[@"title"] = OALocalizedString(@"shared_string_next_update");
    nextUpdateData[@"value"] = [OAWeatherHelper getUpdatesDateFormat:_region.regionId next:YES];
    nextUpdateData[@"value_color"] = UIColor.blackColor;
    nextUpdateData[@"selection_style"] = @(UITableViewCellSelectionStyleNone);
    [infoCells addObject:nextUpdateData];

    NSMutableDictionary *updatesSizeData = [NSMutableDictionary dictionary];
    updatesSizeData[@"key"] = @"updates_size_cell";
    updatesSizeData[@"type"] = [OACustomBasicTableCell getCellIdentifier];
    updatesSizeData[@"title"] = OALocalizedString(@"shared_string_updates_size");
    updatesSizeData[@"value"] = [NSByteCountFormatter stringFromByteCount:[[OAWeatherHelper sharedInstance] getOfflineForecastSizeInfo:_region.regionId local:YES]
                                                                     countStyle:NSByteCountFormatterCountStyleFile];
    updatesSizeData[@"value_color"] = UIColorFromRGB(color_text_footer);
    updatesSizeData[@"right_icon"] = @"ic_custom_arrow_right";
    updatesSizeData[@"right_icon_color"] = UIColorFromRGB(color_tint_gray);
    updatesSizeData[@"selection_style"] = @(UITableViewCellSelectionStyleDefault);
    [infoCells addObject:updatesSizeData];
    _sizeIndexPath = [NSIndexPath indexPathForRow:infoCells.count - 1 inSection:data.count - 1];

    NSMutableDictionary *updateNowData = [NSMutableDictionary dictionary];
    updateNowData[@"key"] = @"update_now_cell";
    updateNowData[@"type"] = [OACustomBasicTableCell getCellIdentifier];
    updateNowData[@"title"] = OALocalizedString(@"osmand_live_update_now");
    updateNowData[@"title_color"] = UIColorFromRGB(color_primary_purple);
    updateNowData[@"right_icon"] = @"ic_custom_download";
    updateNowData[@"right_icon_color"] = UIColorFromRGB(color_primary_purple);
    updateNowData[@"selection_style"] = @(UITableViewCellSelectionStyleDefault);
    updateNowData[@"title_font"] = [UIFont systemFontOfSize:17. weight:UIFontWeightMedium];
    [infoCells addObject:updateNowData];
    _updateNowIndexPath = [NSIndexPath indexPathForRow:infoCells.count - 1 inSection:data.count - 1];

    NSMutableArray<NSMutableDictionary *> *updatesCells = [NSMutableArray array];
    [data addObject:updatesCells];
    [_headers setObject:OALocalizedString(@"update_parameters") forKey:@([data indexOfObject:updatesCells])];
    [_footers setObject:OALocalizedString(@"weather_updates_automatically") forKey:@([data indexOfObject:updatesCells])];

    NSMutableDictionary *updatesFrequencyData = [NSMutableDictionary dictionary];
    updatesFrequencyData[@"key"] = @"updates_frequency_cell";
    updatesFrequencyData[@"type"] = [OACustomBasicTableCell getCellIdentifier];
    updatesFrequencyData[@"title"] = OALocalizedString(@"shared_string_updates_frequency");
    updatesFrequencyData[@"value"] = [OAWeatherHelper getFrequencyFormat:[OAWeatherHelper getPreferenceFrequency:_region.regionId]];
    updatesFrequencyData[@"value_color"] = UIColorFromRGB(color_text_footer);
    updatesFrequencyData[@"right_icon"] = @"ic_custom_arrow_right";
    updatesFrequencyData[@"right_icon_color"] = UIColorFromRGB(color_tint_gray);
    updatesFrequencyData[@"selection_style"] = @(UITableViewCellSelectionStyleDefault);
    [updatesCells addObject:updatesFrequencyData];

    NSMutableDictionary *updateOnlyWiFiData = [NSMutableDictionary dictionary];
    updateOnlyWiFiData[@"key"] = @"update_only_wifi_cell";
    updateOnlyWiFiData[@"type"] = [OACustomBasicTableCell getCellIdentifier];
    updateOnlyWiFiData[@"title"] = OALocalizedString(@"update_only_over_wi_fi");
    updateOnlyWiFiData[@"switch_cell"] = @(YES);
    updateOnlyWiFiData[@"selection_style"] = @(UITableViewCellSelectionStyleNone);
    [updatesCells addObject:updateOnlyWiFiData];

    NSMutableArray<NSMutableDictionary *> *removeCells = [NSMutableArray array];
    [data addObject:removeCells];

    NSMutableDictionary *removeForecastData = [NSMutableDictionary dictionary];
    removeForecastData[@"key"] = @"remove_forecast_cell";
    removeForecastData[@"type"] = [OACustomBasicTableCell getCellIdentifier];
    removeForecastData[@"title"] = OALocalizedString(@"weather_remove_forecast");
    removeForecastData[@"title_color"] = UIColorFromRGB(color_primary_red);
    removeForecastData[@"title_alignment"] = @(NSTextAlignmentCenter);
    removeForecastData[@"title_font"] = [UIFont systemFontOfSize:17. weight:UIFontWeightMedium];
    removeForecastData[@"selection_style"] = @(UITableViewCellSelectionStyleDefault);
    [removeCells addObject:removeForecastData];

    _data = data;
}

- (void)onWeatherSizeCalculated:(id)sender withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (value != _region || !_sizeIndexPath)
            return;

        uint64_t sizeLocal = [_weatherHelper getOfflineForecastSizeInfo:_region.regionId local:YES];
        NSMutableDictionary *totalSizeData = _data[_sizeIndexPath.section][_sizeIndexPath.row];
        NSString *sizeString = [NSByteCountFormatter stringFromByteCount:sizeLocal
                                                              countStyle:NSByteCountFormatterCountStyleFile];
        totalSizeData[@"value"] = sizeString;
        [self.tableView reloadRowsAtIndexPaths:@[_sizeIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    });
}

- (void)onWeatherForecastDownloading:(id)sender withKey:(id)key andValue:(id)value
{
    if (value != _region)
        return;

    if (_updateNowIndexPath && _sizeIndexPath)
    {
        BOOL statusSizeCalculating = ![[OAWeatherHelper sharedInstance] isOfflineForecastSizesInfoCalculated:_region.regionId];
        if ([OAWeatherHelper getPreferenceDownloadState:_region.regionId] == EOAWeatherForecastDownloadStateUndefined && !statusSizeCalculating)
            return;

        dispatch_async(dispatch_get_main_queue(), ^{
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:statusSizeCalculating ? _sizeIndexPath : _updateNowIndexPath];
            if (!cell.accessoryView)
            {
                [self.tableView reloadRowsAtIndexPaths:@[statusSizeCalculating ? _sizeIndexPath : _updateNowIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                cell = [self.tableView cellForRowAtIndexPath:statusSizeCalculating ? _sizeIndexPath : _updateNowIndexPath];
            }

            FFCircularProgressView *progressView = (FFCircularProgressView *) cell.accessoryView;
            NSInteger progressDownloading = [_weatherHelper getOfflineForecastProgressInfo:_region.regionId];
            NSInteger progressDownloadDestination = [[OAWeatherHelper sharedInstance] getProgressDestination:_region.regionId];
            CGFloat progressCompleted = (CGFloat) progressDownloading / progressDownloadDestination;
            if (progressCompleted >= 0.001 && [OAWeatherHelper getPreferenceDownloadState:_region.regionId] == EOAWeatherForecastDownloadStateInProgress)
            {
                progressView.iconPath = nil;
                if (progressView.isSpinning)
                    [progressView stopSpinProgressBackgroundLayer];
                progressView.progress = progressCompleted - 0.001;
            }
            else if ([OAWeatherHelper getPreferenceDownloadState:_region.regionId] == EOAWeatherForecastDownloadStateFinished && !statusSizeCalculating)
            {
                progressView.iconPath = [OAResourcesUIHelper tickPath:progressView];
                progressView.progress = 0.;
                if (!progressView.isSpinning)
                    [progressView startSpinProgressBackgroundLayer];

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self setupView];
                    [self.tableView reloadData];
                    if (self.delegate)
                        [self.delegate onUpdateForecast];
                });
            }
            else
            {
                progressView.iconPath = [UIBezierPath bezierPath];
                progressView.progress = 0.;
                if (!progressView.isSpinning)
                    [progressView startSpinProgressBackgroundLayer];
                [progressView setNeedsDisplay];
            }
        });
    }
}

- (BOOL)isEnabled:(NSString *)key
{
    if ([key isEqualToString:@"update_only_wifi_cell"])
        return [OAWeatherHelper getPreferenceWifi:_region.regionId];

    return NO;
}

- (NSMutableDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (void)onScrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat alpha = (self.tableView.contentOffset.y + defaultNavBarHeight) < 0 ? 0 : ((self.tableView.contentOffset.y + defaultNavBarHeight) / (fabs(self.tableView.contentSize.height - self.tableView.frame.size.height)));
    if (!_isHeaderBlurred && alpha > 0.)
    {
        self.viewNavigationSeparator.hidden = NO;
        _isHeaderBlurred = YES;
    }
    else if (_isHeaderBlurred && alpha <= 0.)
    {
        self.viewNavigationSeparator.hidden = YES;
        _isHeaderBlurred = NO;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OACustomBasicTableCell getCellIdentifier]])
    {
        OACustomBasicTableCell *cell = [tableView dequeueReusableCellWithIdentifier:[OACustomBasicTableCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACustomBasicTableCell getCellIdentifier] owner:self options:nil];
            cell = (OACustomBasicTableCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.rightContentStackView.spacing = 0.;
        }
        if (cell)
        {
            cell.selectionStyle = (UITableViewCellSelectionStyle) [item[@"selection_style"] integerValue];
            [cell switchVisibility:item[@"switch_cell"]];

            [cell valueVisibility:[item.allKeys containsObject:@"value"]];
            cell.valueLabel.text = item[@"value"];
            cell.valueLabel.textColor = item[@"value_color"];

            cell.titleLabel.text = item[@"title"];
            cell.titleLabel.textColor = [item.allKeys containsObject:@"title_color"] ? item[@"title_color"] : UIColor.blackColor;
            cell.titleLabel.textAlignment = [item.allKeys containsObject:@"title_alignment"] ? (NSTextAlignment) [item[@"title_alignment"] integerValue] : NSTextAlignmentNatural;
            cell.titleLabel.font = [item.allKeys containsObject:@"title_font"] ? item[@"title_font"] : [UIFont systemFontOfSize:17.];

            BOOL hasRightIcon = [item.allKeys containsObject:@"right_icon"];
            if (([item[@"key"] isEqualToString:@"update_now_cell"] && [OAWeatherHelper getPreferenceDownloadState:_region.regionId] == EOAWeatherForecastDownloadStateInProgress))
            {
                FFCircularProgressView *progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0., 0., 25., 25.)];
                progressView.iconView = [[UIView alloc] init];
                progressView.tintColor = UIColorFromRGB(color_primary_purple);

                cell.accessoryView = progressView;
                cell.rightIconView.image = nil;
                hasRightIcon = NO;
            }
            else
            {
                cell.accessoryView = nil;
                cell.rightIconView.image = [UIImage templateImageNamed:item[@"right_icon"]];
                cell.rightIconView.tintColor = item[@"right_icon_color"];
            }
            [cell rightIconVisibility:hasRightIcon];
        }
        return cell;
    }

    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_headers objectForKey:@(section)];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [_footers objectForKey:@(section)];
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    OATableViewCustomHeaderView *customHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    NSString *header = [_headers objectForKey:@(section)];
    if ([header isEqualToString:_accuracyDescription])
    {
        customHeader.label.text = header;
        customHeader.label.font = [UIFont systemFontOfSize:13];
        [customHeader setYOffset:20.];
        return customHeader;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([_headers.keyEnumerator.allObjects containsObject:@(section)])
    {
        NSString *header = [_headers objectForKey:@(section)];
        if ([header isEqualToString:_accuracyDescription])
        {
            return [OATableViewCustomHeaderView getHeight:header
                                                    width:tableView.bounds.size.width
                                                  xOffset:20.
                                                  yOffset:20.
                                                     font:[UIFont systemFontOfSize:13.]] + 15.;
        }
        else
        {
            UIFont *font = [UIFont systemFontOfSize:13.];
            CGFloat headerSize = [OAUtilities calculateTextBounds:header
                                                            width:tableView.frame.size.width - (20 + [OAUtilities getLeftMargin]) * 2
                                                             font:font].height + 38.;
            return round(headerSize);
        }
    }

    return 34.;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if ([_footers.keyEnumerator.allObjects containsObject:@(section)])
    {
        UIFont *font = [UIFont systemFontOfSize:13.];
        CGFloat footerSize = [OAUtilities calculateTextBounds:[_footers objectForKey:@(section)]
                                                        width:tableView.frame.size.width - (20 + [OAUtilities getLeftMargin]) * 2
                                                        font:font].height + 16.;

        return round(footerSize);
    }

    return 0.001;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"key"] isEqualToString:@"updates_size_cell"])
    {
        OAWeatherCacheSettingsViewController *controller = [[OAWeatherCacheSettingsViewController alloc] initWithRegion:_region];
        controller.cacheDelegate = self;
        [self presentViewController:controller animated:YES completion:nil];
    }
    else if ([item[@"key"] isEqualToString:@"update_now_cell"])
    {
        if ([OAWeatherHelper getPreferenceDownloadState:_region.regionId] == EOAWeatherForecastDownloadStateInProgress)
        {
            [_weatherHelper prepareToStopDownloading:_region.regionId];
            [_weatherHelper calculateCacheSize:_region onComplete:nil];
        }
        else
        {
            [_weatherHelper downloadForecastByRegion:_region];
        }
    }
    else if ([item[@"key"] isEqualToString:@"remove_forecast_cell"])
    {
        UIAlertController *alert =
                [UIAlertController alertControllerWithTitle:OALocalizedString(@"weather_remove_forecast")
                                                    message:[NSString stringWithFormat:OALocalizedString(@"weather_remove_forecast_description"), _region.name]
                                             preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];

        UIAlertAction *clearCacheAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_remove")
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * _Nonnull action)
                                                                 {
                                                                     [_progressHUD showAnimated:YES whileExecutingBlock:^{
                                                                         [_weatherHelper prepareToStopDownloading:_region.regionId];
                                                                         [_weatherHelper removeLocalForecast:_region.regionId refreshMap:YES];
                                                                     } completionBlock:^{
                                                                         [self dismissViewController];
                                                                         if (self.delegate)
                                                                             [self.delegate onRemoveForecast];
                                                                     }];
                                                                 }
        ];

        [alert addAction:cancelAction];
        [alert addAction:clearCacheAction];

        alert.preferredAction = clearCacheAction;

        [self presentViewController:alert animated:YES completion:nil];
    }
    else if ([item[@"key"] isEqualToString:@"updates_frequency_cell"])
    {
        OAWeatherFrequencySettingsViewController *frequencySettingsViewController =
                [[OAWeatherFrequencySettingsViewController alloc] initWithRegion:_region];
        frequencySettingsViewController.frequencyDelegate = self;
        [self presentViewController:frequencySettingsViewController animated:YES completion:nil];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Selectors

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];

        if ([item[@"key"] isEqualToString:@"update_only_wifi_cell"])
            [OAWeatherHelper setPreferenceWifi:_region.regionId value:switchView.isOn];

        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - OAWeatherCacheSettingsDelegate

- (void)onCacheClear
{
    [_weatherHelper calculateCacheSize:_region onComplete:nil];
}

#pragma mark - OAWeatherFrequencySettingsDelegate

- (void)onFrequencySelected
{
    for (NSInteger i = 0; i < _data.count; i++)
    {
        NSArray<NSMutableDictionary *> *cells = _data[i];
        for (NSInteger j = 0; j < cells.count; j++)
        {
            NSMutableDictionary *cell = cells[j];
            if ([cell[@"key"] isEqualToString:@"next_update_cell"])
            {
                cell[@"value"] = [OAWeatherHelper getUpdatesDateFormat:_region.regionId next:YES];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:j inSection:i]]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            else if ([cell[@"key"] isEqualToString:@"updates_frequency_cell"])
            {
                cell[@"value"] = [OAWeatherHelper getFrequencyFormat:[OAWeatherHelper getPreferenceFrequency:_region.regionId]];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:j inSection:i]]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    }
}

@end
