//
//  PGActionIndex.m
//  XCActionBar
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionProvider.h"
#import "PGActionIndex.h"
#import "XCActionInterface.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface PGActionIndex () <XCActionProviderDelegate>

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
- (id<NSCopying>)registerProvider:(id<XCActionProvider>)provider
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
    
    for(id<XCActionProvider> provider in [self.providers allValues]) {
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
- (NSArray *)lookup:(NSString *)query
{
    NSArray *queryComponents       = [query componentsSeparatedByString:@" "];
    NSUInteger queryComponentCount = queryComponents.count;
    
    ////////////////////////////////////////////////////////////////////////////////
    // this is highly inefficient - obviously just a first pass to get the core feature working
    ////////////////////////////////////////////////////////////////////////////////
    NSMutableArray *matches = [NSMutableArray array];

    for(id<XCActionInterface> action in self.index) {

        NSString *stringToMatch = action.title;

        BOOL foundMatch = NO;

        ////////////////////////////////////////////////////////////////////////////////
        // Search Title and Title's subwords
        ////////////////////////////////////////////////////////////////////////////////
        while(query.length <= stringToMatch.length) {
            NSRange range = [stringToMatch rangeOfString:query
                                                options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)
                                                  range:NSMakeRange(0, query.length)];
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
        
        if(foundMatch == YES) continue;
        if(queryComponentCount < 2) continue;

        ////////////////////////////////////////////////////////////////////////////////
        // Run additional sub-word prefix search
        // This allows us to match partial prefixes matches such as:
        // "Sur wi d q" would match "Surround with double quotes"
        ////////////////////////////////////////////////////////////////////////////////
        NSArray *candidateComponents = [action.title componentsSeparatedByString:@" "];
        if(queryComponentCount > candidateComponents.count) continue;
        
        BOOL foundPartialMatch = NO;
        for(int i = 0; i < queryComponentCount; i++) {
            foundPartialMatch = NO;
            
            NSString *subQuery = queryComponents[i];
            NSString *subMatch = candidateComponents[i];
            
            if(subQuery.length > subMatch.length) break;
            
            NSRange range = [subMatch rangeOfString:subQuery
                                                 options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)
                                                   range:NSMakeRange(0, subQuery.length)];
            foundPartialMatch = (range.location != NSNotFound);
            if(foundPartialMatch == NO) break;
        }
        
        if(foundPartialMatch == YES) {
            [matches addObject:action];
            break;
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
- (void)actionProviderDidNotifyOfIndexRebuildNeeded:(id<XCActionProvider>)provider
{
    TRLog(@"<IndexRebuildNeeded>, <provider=%@>", provider);
    
    RTVDeclareWeakSelf(weakSelf);
    
    void (^RegisterProviderDelegates)(id<XCActionProviderDelegate> delegate) = ^(id delegate){
        NSArray *providers = nil;
        @synchronized(self) {
            providers = [[weakSelf.providers allValues] copy];
        }

        for(id<XCActionProvider> provider in providers) {
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
    for(id<XCActionProvider> provider in providers) {
        NSArray *actions = [provider findAllActions];
        [actionIndex addObjectsFromArray:actions];
    }
    self.index = [NSArray arrayWithArray:actionIndex];;
}

@end
