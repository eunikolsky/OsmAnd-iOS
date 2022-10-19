//
//  OAIconTitleValueCell.m
//  OsmAnd
//
//  Created by Paul on 01.06.19.
//  Copyright (c) 2019 OsmAnd. All rights reserved.
//

#import "OAIconTitleValueCell.h"

@implementation OAIconTitleValueCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self showBottomDescription:NO];

    if ([self.descriptionView isDirectionRTL])
    {
        self.descriptionView.textAlignment = NSTextAlignmentLeft;
        [self.rightIconView setImage:self.rightIconView.image.imageFlippedForRightToLeftLayoutDirection];
    }
}

- (void)updateConstraints
{
    BOOL hasLeftIcon = !self.leftIconView.hidden;
    BOOL hasRightIcon = !self.rightIconView.hidden;
    BOOL hasBottomDescription = !self.bottomDescriptionView.hidden;

    self.leftIconTextLeadingMargin.active = hasLeftIcon;
    self.noLeftIconTextLeadingMargin.active = !hasLeftIcon;
    self.leftIconBottomDescriptionLeadingMargin.active = hasLeftIcon;
    self.noLeftIconBottomDescriptionLeadingMargin.active = !hasLeftIcon;

    self.rightIconDescLeadingMargin.active = hasRightIcon;
    self.noRightIconDecsLeadingMargin.active = !hasRightIcon;

    self.bottomDescriptionMargin.active = hasBottomDescription;
    self.noBottomDescriptionMargin.active = !hasBottomDescription;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasLeftIcon = !self.leftIconView.hidden;
        BOOL hasRightIcon = !self.rightIconView.hidden;
        BOOL hasBottomDescription = !self.bottomDescriptionView.hidden;

        res = res || self.leftIconTextLeadingMargin.active != hasLeftIcon;
        res = res || self.noLeftIconTextLeadingMargin.active != !hasLeftIcon;
        res = res || self.leftIconBottomDescriptionLeadingMargin.active != hasLeftIcon;
        res = res || self.noLeftIconBottomDescriptionLeadingMargin.active != !hasLeftIcon;

        res = res || self.rightIconDescLeadingMargin.active != hasRightIcon;
        res = res || self.noRightIconDecsLeadingMargin.active != !hasRightIcon;

        res = res || self.bottomDescriptionMargin.active != hasBottomDescription;
        res = res || self.noBottomDescriptionMargin.active != !hasBottomDescription;
    }
    return res;
}

- (void)showLeftIcon:(BOOL)show
{
    self.leftIconView.hidden = !show;
}

- (void)showRightIcon:(BOOL)show
{
    self.rightIconView.hidden = !show;
}

- (void)showBottomDescription:(BOOL)show
{
    self.bottomDescriptionView.hidden = !show;
}

@end
