//
//  PGNSMenuActionProvider.m
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "PGNSMenuActionProvider.h"
#import "PGBlockAction.h"
#import "PGUtils.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface PGNSMenuActionProvider ()

@property (nonatomic,   weak) NSMenu  *menu;
@property (nonatomic, strong) NSArray *actions;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation PGNSMenuActionProvider

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithMenu:(NSMenu *)menu
{
    if((self = [super init])) {
        self.actions = [NSMutableArray array];
        self.menu    = menu;
        
        TRLog(@"<menu=%@, items=%@>", menu.title, menu.itemArray);
    }
    return self;
}

#pragma mark - PGActionProvider

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)prepareActionsOnQueue:(dispatch_queue_t)indexerQueue
            completionHandler:(PGGeneralCompletionHandler)completionHandler;
{
    RTVDeclareWeakSelf(weakSelf);

    dispatch_async(indexerQueue, ^{
        [weakSelf buildAvailableActions];
        if(completionHandler) completionHandler();
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)prepareActionsWithCompletionHandler:(PGGeneralCompletionHandler)completionHandler
{
    RTVDeclareWeakSelf(weakSelf);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf buildAvailableActions];
        if(completionHandler) completionHandler();
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)actionCategory
{
    return @"Menu Actions";
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)actionGroupName
{
    return self.menu.title;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)findAllActions
{
    return @[];
}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)findActionsMatchingExpression:(NSString *)expression
{
    return @[];
}

#pragma mark - Notification Handlers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)handleMenuWasUpdatedNotification:(NSNotification *)notification
{
    // In the future we probably want to be a bit more efficient about this
    [self prepareActionsWithCompletionHandler:nil];
}

#pragma mark - Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)registerObservers
{
    //    APPKIT_EXTERN NSString *NSMenuDidAddItemNotification;
    //    APPKIT_EXTERN NSString *NSMenuDidRemoveItemNotification;
    //    APPKIT_EXTERN NSString *NSMenuDidChangeItemNotification;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)deregisterObservers
{
    
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)buildAvailableActions
{
    [self deregisterObservers];
    
    RTVDeclareWeakSelf(weakSelf);
    
    NSMutableArray *actions = [NSMutableArray array];
    
    TRLog(@"%@: buildAvaiableActions (%@)", self.description, self.menu.title);
    for(NSMenuItem *item in self.menu.itemArray) { @autoreleasepool {
        PGBlockAction *action = [[PGBlockAction alloc] initWithTitle:item.title
                                                            subtitle:@""
                                                                hint:[self buildHintForMenuItem:item]
                                                              action:^{
                                                                  NSUInteger index = [weakSelf.menu indexOfItem:item];
                                                                  [weakSelf.menu performActionForItemAtIndex:index];
                                                              }];
        [actions addObject:action];
        TRLog(@"<action:: title=%@, subtitle=%@, hint=%@>", action.title, action.subtitle, action.hint);
    }}
    
    [self registerObservers];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)buildHintForMenuItem:(NSMenuItem *)item
{
    return [NSString stringWithFormat:@"%@%@",
            PGBuildModifierKeyMaskString(item.keyEquivalentModifierMask),
            item.keyEquivalent.uppercaseString];
}

@end
