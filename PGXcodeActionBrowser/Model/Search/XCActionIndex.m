//
//  XCActionIndex.m
//  XCActionBar
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCUtils.h"

#import "XCActionProvider.h"
#import "XCActionIndex.h"
#import "XCActionInterface.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCActionIndex () <XCActionProviderDelegate>

@property (nonatomic) dispatch_queue_t    indexerQueue;
@property (nonatomic) NSMutableDictionary *providers;
@property (nonatomic) NSMutableDictionary *actionsByProvider;
@property (nonatomic) NSArray             *index;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCActionIndex

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    if((self = [super init])) {
        self.indexerQueue      = dispatch_queue_create("org.pedrogomes.XCActionBar.ActionIndexer", DISPATCH_QUEUE_CONCURRENT);
        self.providers         = [NSMutableDictionary dictionary];
        self.actionsByProvider = [NSMutableDictionary dictionary];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id<NSCopying>)registerProvider:(id<XCActionProvider>)provider
{
    NSString *token = [[NSUUID UUID] UUIDString];

    @synchronized(self) {
        provider.delegate = self;
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
    XCDeclareWeakSelf(weakSelf);

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

        ////////////////////////////////////////////////////////////////////////////////
        // Search Title and Title's subwords
        ////////////////////////////////////////////////////////////////////////////////
        BOOL        foundMatch    = NO;
        NSUInteger  matchLocation = 0;

        while(query.length <= stringToMatch.length) {
            NSRange range = [stringToMatch rangeOfString:query
                                                 options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)
                                                   range:NSMakeRange(0, query.length)];
            if(range.location != NSNotFound) {
                [matches addObject:action];
                action.searchQueryMatchRanges = @[[NSValue valueWithRange:NSMakeRange(matchLocation, query.length)]];
                foundMatch = YES;
                break;
            }
            NSRange rangeForNextMatch = [stringToMatch rangeOfString:@" "];
            if(rangeForNextMatch.location == NSNotFound) break;
            if(rangeForNextMatch.location + 1 > stringToMatch.length) break;
            
            matchLocation += rangeForNextMatch.location + 1;
            stringToMatch = [stringToMatch substringFromIndex:rangeForNextMatch.location + 1];
        }
        
        if(foundMatch == YES) continue;
        if(queryComponentCount < 2) continue;

        ////////////////////////////////////////////////////////////////////////////////
        // Run additional sub-word prefix search
        // This allows us to match partial prefixes matches such as:
        // "Sur wi d q" would match "Surround with double quotes"
        ////////////////////////////////////////////////////////////////////////////////
        NSMutableArray *ranges  = [NSMutableArray array];

        NSArray *candidateComponents = [action.title componentsSeparatedByString:@" "];
        if(queryComponentCount > candidateComponents.count) continue;
        
        matchLocation = 0;
        
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

            [ranges addObject:[NSValue valueWithRange:NSMakeRange(matchLocation, subQuery.length)]];
            matchLocation += (subMatch.length + 1);
        }
        
        if(foundPartialMatch == YES) {
            action.searchQueryMatchRanges = ranges;
            [matches addObject:action];
            continue;
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
    XCLog(@"<IndexRebuildNeeded>, <provider=%@>, <updating...>", provider);
    
    XCDeclareWeakSelf(weakSelf);
    
    NSString *hashForProvider = XCHashObject(provider);
    [provider prepareActionsOnQueue:self.indexerQueue completionHandler:^{
        @synchronized(self) {
            NSArray *oldActions = weakSelf.actionsByProvider[hashForProvider];
            
            NSMutableArray *index = weakSelf.index.mutableCopy;
            [index removeObjectsInArray:oldActions];
            
            NSArray  *actions = [provider findAllActions];
            [index addObjectsFromArray:actions];
            
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
            [index sortUsingDescriptors:@[sortDescriptor]];
            
            weakSelf.index = [NSArray arrayWithArray:index];
            weakSelf.actionsByProvider[hashForProvider] = actions;
        }
        
        XCLog(@"<IndexRebuildNeeded>, <provider=%@>, <complete>", provider);
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
    for(id<XCActionProvider> provider in providers) { @autoreleasepool {
        NSString *hashForProvider = XCHashObject(provider);
        NSArray  *actions         = [provider findAllActions];
        
        self.actionsByProvider[hashForProvider] = actions;
        
        [actionIndex addObjectsFromArray:actions];
    }}
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    [actionIndex sortUsingDescriptors:@[sortDescriptor]];
    
    self.index = [NSArray arrayWithArray:actionIndex];;
}

@end
