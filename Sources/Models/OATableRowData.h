//
//  OATableViewRowData.h
//  OsmAnd Maps
//
//  Created by Paul on 20.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EOATableRowType) {
    EOATableRowTypeRegular,
    EOATableRowTypeCollapsable
};

@interface OATableRowData : NSObject

#define kCellTypeKey @"cellType"
#define kCellKeyKey @"key"
#define kCellTitleKey @"title"
#define kCellDescrKey @"descr"
#define kCellIconNameKey @"iconName"
#define kCellIconTint @"iconTint"
#define kCellSecondaryIconName @"secondaryIconName"

+ (instancetype) rowData;

- (instancetype)initWithData:(NSDictionary *)data;

@property (nonatomic) NSString *cellType;
@property (nonatomic) NSString *key;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *descr;
@property (nonatomic) NSString *iconName;
@property (nonatomic) NSInteger iconTint;
@property (nonatomic) NSString *secondaryIconName;

@property (nonatomic, readonly, assign) EOATableRowType rowType;

- (void) setObj:(id)data forKey:(nonnull NSString *)key;
- (id) objForKey:(nonnull NSString *)key;

- (NSString *) stringForKey:(nonnull NSString *)key;
- (NSInteger) integerForKey:(nonnull NSString *)key;
- (BOOL) boolForKey:(nonnull NSString *)key;

- (NSInteger) dependentRowsCount;
- (OATableRowData *) getDependentRow:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
