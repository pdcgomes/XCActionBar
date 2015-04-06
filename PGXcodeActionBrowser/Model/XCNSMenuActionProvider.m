//
//  XCNSMenuActionProvider.m
//  XCActionBar
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCNSMenuActionProvider.h"
#import "XCBlockAction.h"
#import "XCUtils.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCNSMenuActionProvider ()

@property (nonatomic,   weak) NSMenu  *menu;
@property (nonatomic        ) NSArray *actions;
@property (nonatomic        ) NSTimer *notifyOfIndexRebuildRequiredTimer;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCNSMenuActionProvider

@synthesize delegate = _delegate;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
    [self deregisterObservers];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithMenu:(NSMenu *)menu
{
    if((self = [super init])) {
        self.actions = [NSMutableArray array];
        self.menu    = menu;
        
//        XCLog(@"<menu=%@, items=%@>", menu.title, menu.itemArray);
    }
    return self;
}

#pragma mark - PGActionProvider

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)setDelegate:(id<XCActionProviderDelegate>)delegate
{
    if(_delegate == delegate) return;
    _delegate = delegate;
    
    [self deregisterObservers];

    XCReturnUnless(self.respondToMenuChanges == YES);

    if(TRCheckIsEmpty(delegate) == NO) [self registerObservers];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)prepareActionsOnQueue:(dispatch_queue_t)indexerQueue
            completionHandler:(PGGeneralCompletionHandler)completionHandler;
{
    XCDeclareWeakSelf(weakSelf);

    dispatch_async(indexerQueue, ^{
        [weakSelf buildAvailableActions];
        if(completionHandler) completionHandler();
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)prepareActionsWithCompletionHandler:(PGGeneralCompletionHandler)completionHandler
{
    XCDeclareWeakSelf(weakSelf);
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
    return [NSArray arrayWithArray:self.actions];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyOfIndexRebuildRequired:) name:NSMenuDidAddItemNotification object:self.menu];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyOfIndexRebuildRequired:) name:NSMenuDidRemoveItemNotification object:self.menu];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyOfIndexRebuildRequired:) name:NSMenuDidChangeItemNotification object:self.menu];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)deregisterObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)buildAvailableActions
{
    [self deregisterObservers];
    
    self.actions = [self recursivelyBuildAvailableActionsForMenu:self.menu];

    BOOL registerObservers = (self.respondToMenuChanges && self.delegate);
    if(registerObservers) [self registerObservers];
}

////////////////////////////////////////////////////////////////////////////////
// Recursive approach
////////////////////////////////////////////////////////////////////////////////
//- (NSArray *)recursivelyBuildAvailableActionsForMenu:(NSMenu *)menu
//{
//    NSMutableArray *actions = [NSMutableArray array];
//    
//    for(NSMenuItem *item in menu.itemArray) { @autoreleasepool {
//        PGBlockAction *action = [[PGBlockAction alloc] initWithTitle:item.title
//                                                            subtitle:menu.title
//                                                                hint:[self buildHintForMenuItem:item]
//                                                              action:^{
//                                                                  NSUInteger index = [menu indexOfItem:item];
//                                                                  [menu performActionForItemAtIndex:index];
//                                                              }];
//        [actions addObject:action];
//        if(item.submenu == nil) continue;
//        
//        NSArray *subActions = [self recursivelyBuildAvailableActionsForMenu:item.submenu];
//        if(TRCheckIsEmpty(subActions) == NO) {
//            [actions addObjectsFromArray:subActions];
//        }
//        XCLog(@"<action:: title=%@, subtitle=%@, hint=%@>", action.title, action.subtitle, action.hint);
//    }}
//    
//    return [NSArray arrayWithArray:actions];
//}

////////////////////////////////////////////////////////////////////////////////
// Stack based approach
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)recursivelyBuildAvailableActionsForMenu:(NSMenu *)menu
{
    NSMutableArray *actions = [NSMutableArray array];
    
    NSMutableArray *processingQueue = [NSMutableArray arrayWithObject:menu];
    
    while(processingQueue.count > 0) {
        NSMenu *menu = [processingQueue firstObject];
        [processingQueue removeObjectAtIndex:0];
        
        NSString *subtitle = [self buildSubtitleForMenu:menu];
        
        for(NSMenuItem *item in menu.itemArray) { @autoreleasepool {

            // Do not index items representing submenus, but add them to the queue so we can process its subitems
            if(item.submenu) {
                [processingQueue addObject:item.submenu];
                continue;
            }
            
            // Build the action
            BOOL buildHint = (item.image == nil &&
                              TRCheckIsEmpty(item.keyEquivalent) == NO);
            XCBlockAction *action = [[XCBlockAction alloc] initWithTitle:item.title
                                                                subtitle:subtitle
                                                                    hint:(buildHint ? [self buildHintForMenuItem:item] : @"")
                                                                  action:^(id<XCIDEContext> context) {
                                                                      NSUInteger index = [menu indexOfItem:item];
                                                                      [menu performActionForItemAtIndex:index];
                                                                  }];
            action.representedObject = item;
//            action.category = [self actionCategory];
            action.group    = [self actionGroupName];
            [actions addObject:action];
            
            if(item.submenu) [processingQueue addObject:item.submenu];
            
//            XCLog(@"<action:: title=%@, subtitle=%@, hint=%@>", action.title, action.subtitle, action.hint);
        }}
    }
    
    return [NSArray arrayWithArray:actions];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)buildHintForMenuItem:(NSMenuItem *)item
{
//    if([item.title.lowercaseString isEqualToString:@"always backlight"]) {
//        NSLog(@"");
//    }
    return [NSString stringWithFormat:@"%@%@",
            XCBuildModifierKeyMaskString(item.keyEquivalentModifierMask),
            item.keyEquivalent.uppercaseString];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)buildSubtitleForMenu:(NSMenu *)menu
{
    NSMutableString *title     = [[NSMutableString alloc] initWithString:menu.title];
    NSMutableArray *components = [NSMutableArray arrayWithObject:title];
    
    NSMenu *parentMenu = menu.supermenu;
    while(parentMenu) {
        [components insertObject:[NSString stringWithFormat:@"%@ > ", parentMenu.title]
                         atIndex:0];
        parentMenu = parentMenu.supermenu;
    }
    [components removeObjectAtIndex:0]; // get rid of the top level Xcode menu reference
    return [components componentsJoinedByString:@""];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)notifyOfIndexRebuildRequired:(NSNotification *)notification
{
//    XCLog(@"<notification=%@>", notification);
    
    XCReturnUnless([self.delegate respondsToSelector:@selector(actionProviderDidNotifyOfIndexRebuildNeeded:)]);
    
    [self.notifyOfIndexRebuildRequiredTimer invalidate];
    self.notifyOfIndexRebuildRequiredTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                                              target:self
                                                                            selector:@selector(notifyOfIndexRebuildRequired)
                                                                            userInfo:nil
                                                                             repeats:NO];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)notifyOfIndexRebuildRequired
{
    [self.delegate actionProviderDidNotifyOfIndexRebuildNeeded:self];
}

@end
