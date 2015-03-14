//
//  PGActionIndex.m
//  XCActionBar
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

@property (nonatomic, strong) dispatch_queue_t      indexerQueue;
@property (nonatomic, strong) NSMutableDictionary   *providers;
@property (nonatomic, strong) NSArray               *index;

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
        self.providers    = [NSMutableDictionary dictionary];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id<NSCopying>)registerProvider:(id<PGActionProvider>)provider
{
    NSString *token = [[NSUUID UUID] UUIDString];

    @synchronized(self) {
        self.providers[token] = provider;
    }
    
    return token;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)deregisterProvider:(id<NSCopying>)providerToken;
{
    @synchronized(self) {
        [self.providers removeObjectForKey:providerToken];
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
    
    for(id<PGActionProvider> provider in [self.providers allValues]) {
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

        NSString *stringToMatch = action.title;

        BOOL foundMatch = NO;

        ////////////////////////////////////////////////////////////////////////////////
        // Search Title and Title's subwords
        ////////////////////////////////////////////////////////////////////////////////
        while(str.length <= stringToMatch.length) {
            NSRange range = [stringToMatch rangeOfString:str
                                                options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)
                                                  range:NSMakeRange(0, str.length)];
            if(range.location != NSNotFound) {
                [matches addObject:action];
                foundMatch = YES;
                break;
            }
            NSRange rangeForNextMatch = [stringToMatch rangeOfString:@" "];
            if(rangeForNextMatch.location == NSNotFound) break;
            if(rangeForNextMatch.location + 1 > stringToMatch.length) break;
            
            stringToMatch = [stringToMatch substringFromIndex:rangeForNextMatch.location + 1];
        }
        
        ////////////////////////////////////////////////////////////////////////////////
        // No matches ...
        // lets try the action's group instead
        ////////////////////////////////////////////////////////////////////////////////
//        if(foundMatch == NO) {
//            if(str.length > action.group.length) continue;
//
//            NSRange range = [action.group rangeOfString:str
//                                                options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)
//                                                  range:NSMakeRange(0, str.length)];
//            if(range.location != NSNotFound) {
//                [matches addObject:action];
//            }
//        }
    }
    
    return [NSArray arrayWithArray:matches];
}

#pragma mark - PGActionProviderDelegate

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)actionProviderDidNotifyOfIndexRebuildNeeded:(id<PGActionProvider>)provider
{
    TRLog(@"<IndexRebuildNeeded>, <provider=%@>", provider);
    
    RTVDeclareWeakSelf(weakSelf);
    
    void (^RegisterProviderDelegates)(id<PGActionBrowserProviderDelegate> delegate) = ^(id delegate){
        NSArray *providers = nil;
        @synchronized(self) {
            providers = [[weakSelf.providers allValues] copy];
        }

        for(id<PGActionProvider> provider in providers) {
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
        providers = [[self.providers allValues] copy];
    }
    
    NSMutableArray *actionIndex = [NSMutableArray array];
    for(id<PGActionProvider> provider in providers) {
        NSArray *actions = [provider findAllActions];
        [actionIndex addObjectsFromArray:actions];
    }
    self.index = [NSArray arrayWithArray:actionIndex];;
}

@end
