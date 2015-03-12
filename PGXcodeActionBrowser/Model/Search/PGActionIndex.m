//
//  PGActionIndex.m
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "PGActionBrowserProvider.h"
#import "PGActionIndex.h"
#import "PGActionInterface.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface PGActionIndex () <PGActionBrowserProviderDelegate>

@property (nonatomic, strong) dispatch_queue_t indexerQueue;
@property (nonatomic, strong) NSMutableArray   *providers;
@property (nonatomic, strong) NSArray          *index;

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
    @synchronized(self) {
        [self.providers addObject:provider];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)updateWithCompletionHandler:(PGGeneralCompletionHandler)completionHandler
{
    ////////////////////////////////////////////////////////////////////////////////
    // Build All Actions
    ////////////////////////////////////////////////////////////////////////////////
    dispatch_group_t group = dispatch_group_create();
    
    for(id<PGActionBrowserProvider> provider in self.providers) {
        dispatch_group_enter(group);
        
        [provider prepareActionsOnQueue:self.indexerQueue completionHandler:^{
            dispatch_group_leave(group);
        }];
    }

    ////////////////////////////////////////////////////////////////////////////////
    // When done, collect all actions into our internal index
    ////////////////////////////////////////////////////////////////////////////////
    RTVDeclareWeakSelf(weakSelf);

    dispatch_group_enter(group);
    dispatch_barrier_async(self.indexerQueue, ^{
        [weakSelf rebuildIndex];
        dispatch_group_leave(group);
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), completionHandler);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)lookup:(NSString *)str
{
    ////////////////////////////////////////////////////////////////////////////////
    // this is highly inefficient - obviously just a first pass to get the core feature working
    ////////////////////////////////////////////////////////////////////////////////
    NSMutableArray *matches = [NSMutableArray array];
    
    for(id<PGActionInterface> action in self.index) {
        if(str.length > action.title.length) continue;
        
        NSRange range = [action.title rangeOfString:str
                                            options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)
                                              range:NSMakeRange(0, str.length)];
        if(range.location == NSNotFound) continue;
        [matches addObject:action];
    }
    
    return [NSArray arrayWithArray:matches];
}

#pragma mark - PGActionProviderDelegate

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)actionProviderDidNotifyOfIndexRebuildNeeded:(id<PGActionBrowserProvider>)provider
{
    TRLog(@"<IndexRebuildNeeded>, <provider=%@>", provider);
    
    RTVDeclareWeakSelf(weakSelf);
    
    void (^RegisterProviderDelegates)(id<PGActionBrowserProviderDelegate> delegate) = ^(id delegate){
        NSArray *providers = nil;
        @synchronized(self) {
            providers = [weakSelf.providers copy];
        }

        for(id<PGActionBrowserProvider> provider in weakSelf.providers) {
            [provider setDelegate:delegate];
        }
    };
    
    RegisterProviderDelegates(nil);
    
    [self updateWithCompletionHandler:^{
        RegisterProviderDelegates(weakSelf);
    }];
}

#pragma mark - Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)rebuildIndex
{
    NSArray *providers = nil;
    @synchronized(self) {
        providers = [self.providers copy];
    }
    
    NSMutableArray *actionIndex = [NSMutableArray array];
    for(id<PGActionBrowserProvider> provider in providers) {
        NSArray *actions = [provider findAllActions];
        [actionIndex addObjectsFromArray:actions];
    }
    self.index = [NSArray arrayWithArray:actionIndex];;
}

@end
