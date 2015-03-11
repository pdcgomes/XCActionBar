//
//  PGActionIndex.m
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "PGActionBrowserProvider.h"
#import "PGActionIndex.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface PGActionIndex ()

@property (nonatomic, strong) dispatch_queue_t indexerQueue;
@property (nonatomic, strong) NSMutableArray   *providers;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation PGActionIndex

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    if((self = [super init])) {
        self.indexerQueue = dispatch_queue_create("org.pedrogomes.XcodeActionBrowser.ActionIndexer", DISPATCH_QUEUE_CONCURRENT);
        self.providers    = [NSMutableArray array];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)registerProvider:(id<PGActionBrowserProvider>)provider
{
    [self.providers addObject:provider];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)updateWithCompletionHandler:(PGGeneralCompletionHandler)completionHandler
{
    dispatch_group_t group = dispatch_group_create();
    
    for(id<PGActionBrowserProvider> provider in self.providers) {
        dispatch_group_enter(group);
        
        [provider prepareActionsOnQueue:self.indexerQueue completionHandler:^{
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), completionHandler);
}

@end
