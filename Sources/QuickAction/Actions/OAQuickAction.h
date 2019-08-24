//
//  OAQuickAction.h
//  OsmAnd
//
//  Created by Paul on 8/6/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OrderedDictionary.h"
#import "Localization.h"

#define kSectionNoName @"no_name"

@class OrderedDictionary;

typedef NS_ENUM(NSInteger, EOAQuickActionType)
{
    EOAQuickActionTypeNew = 1,
    EOAQuickActionTypeMarker,
    EOAQuickActionTypeFavorite,
    EOAQuickActionTypeShowFavorite,
    EOAQuickActionTypeTogglePOI,
    EOAQuickActionTypeGPX,
    EOAQuickActionTypeParking,
    EOAQuickActionTypeTakeAudioNote,
    EOAQuickActionTypeTakeVideoNote,
    EOAQuickActionTypeTakePhoto,
    EOAQuickActionTypeNavVoice,
    EOAQuickActionTypeAddNote,
    EOAQuickActionTypeAddPOI,
    EOAQuickActionTypeMapStyle,
    EOAQuickActionTypeMapOverlay,
    EOAQuickActionTypeMapUnderlay,
    EOAQuickActionTypeMapSource,
    EOAQuickActionTypeAddDestination,
    EOAQuickActionTypeReplaceDestination,
    EOAQuickActionTypeAddFirstIntermediate,
    EOAQuickActionTypeAutoZoomMap,
    EOAQuickActionTypeToggleOsmNotes,
    EOAQuickActionTypeToggleLocalEditsLayer,
    EOAQuickActionTypeToggleNavigation,
    EOAQuickActionTypeResumePauseNavigation,
    EOAQuickActionTypeToggleDayNight,
    EOAQuickActionTypeToggleGPX
};

@interface OAQuickAction : NSObject

@property (nonatomic) EOAQuickActionType type;
@property (nonatomic) long identifier;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic) NSDictionary<NSString *, NSString *> *params;

- (instancetype) initWithType:(NSInteger)type name:(NSString *)name;
- (instancetype) initWithType:(NSInteger)type;
- (instancetype) initWithAction:(OAQuickAction *)action;

-(NSString *) getIconResName;
-(NSString *) getSecondaryIconName;
-(BOOL) hasSecondaryIcon;

-(long) getId;
-(EOAQuickActionType)getType;
-(BOOL) isActionEditable;
-(BOOL) isActionEnabled;
-(NSString *) getName;

-(NSDictionary *) getParams;
-(void) setName:(NSString *) name;
-(void) setParams:(NSDictionary<NSString *, NSString *> *) params;
-(BOOL) isActionWithSlash;
-(NSString *) getActionText;

//public void setAutoGeneratedTitle(EditText title){
//}

-(void) execute;
-(void) drawUI;
-(OrderedDictionary *)getUIModel;
-(BOOL) fillParams:(NSDictionary *)model;

-(BOOL) hasInstanceInList:(NSArray<OAQuickAction *> *)active;
-(NSString *)getTitle:(NSArray *)filters;
-(NSString *) getListKey;

@end
