//
//  OADownloadTask.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/14/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAObservable.h"

typedef NS_ENUM(NSInteger, OADownloadTaskState) {
    OADownloadTaskStateUnknown = -1,
    OADownloadTaskStateRunning = 0,
    OADownloadTaskStatePaused = 1,
    OADownloadTaskStateStopping = 2,
    OADownloadTaskStateFinished = 3,
};

@protocol OADownloadTask <NSObject>

@required

@property(readonly, copy) NSURLRequest *originalRequest;
@property(readonly, copy) NSURLRequest *currentRequest;
@property(readonly, copy) NSURLResponse *response;

@property(readonly) NSString* targetPath;
@property(readonly) NSString* key;
@property(readonly) NSString* name;

@property(readonly) OADownloadTaskState state;
- (void)resume;
- (void)pause;
- (void)stop;
- (void)cancel;

@property(readonly) OAObservable* progressCompletedObservable;
@property(readonly) float progressCompleted;

@property(readonly) OAObservable* completedObservable;

@property(readonly, copy) NSError *error;

@property int installResourceRetry;
@property BOOL silentInstall;

@end
