//
//  PGXcodeActionBrowser.m
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "PGXcodeActionBrowser.h"

#import "PGActionIndex.h"
#import "PGSearchService.h"

#import "PGNSMenuActionProvider.h"
#import "PGWorkspaceUnitTestsActionProvider.h"

#import "PGActionBrowserWindowController.h"

#import "IDEIndex.h"
#import "IDEWorkspace.h"
#import "DVTFilePath.h"

#define XCIDEWorkspaceKey(_workspace_) [_workspace_.representingFilePath pathString]

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
static PGXcodeActionBrowser *sharedPlugin;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface PGXcodeActionBrowser()

@property (nonatomic, strong, readwrite) NSBundle *bundle;

@property (nonatomic, strong) id<PGActionIndex  > actionIndex;
@property (nonatomic, strong) id<PGSearchService> searchService;

@property (nonatomic, strong) NSMutableDictionary *providersByWorkspace;

@property (nonatomic, strong) PGActionBrowserWindowController *windowController;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation PGXcodeActionBrowser

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
            TRLog(@"Pluging Loaded!");
        });
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        self.bundle = plugin;
        self.providersByWorkspace = [NSMutableDictionary dictionary];
        
        ////////////////////////////////////////////////////////////////////////////////
        // General initialization
        ////////////////////////////////////////////////////////////////////////////////
        [self performInitialization];
        [self registerObservers];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)presentActionSearchBar
{
    if(self.windowController == nil) {
        self.windowController = [[PGActionBrowserWindowController alloc] initWithBundle:self.bundle];
        // REVIEW: initWithBundle:searchService:
        self.windowController.searchService = self.searchService;
    }
    
    [self centerWindowInScreen:[self.windowController window]];
    [self.windowController showWindow:self];
    [self.windowController becomeFirstResponder];
}

#pragma mark - Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)performInitialization
{
    self.actionIndex   = [[PGActionIndex alloc] init];
    self.searchService = [[PGSearchService alloc] initWithIndex:self.actionIndex];
    
    [self buildMenuActions];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)buildMenuActions
{
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Window"];
    if(menuItem == nil) return;
    
    [menuItem.submenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Action Browser (indexing...)"
                                                            action:@selector(presentActionSearchBar)
                                                     keyEquivalent:@"8"];
    actionMenuItem.keyEquivalentModifierMask = (NSCommandKeyMask | NSShiftKeyMask);
    actionMenuItem.target  = self;
    actionMenuItem.enabled = NO;
    
    [menuItem.submenu insertItem:actionMenuItem
                         atIndex:[menuItem.submenu indexOfItemWithTitle:@"Bring All to Front"] - 1];
    
    TRLog(@"Indexing actions ...");
    
    [self buildActionProviders];
    [self buildActionIndexWithCompletionHandler:^{
        actionMenuItem.title   = @"Action Browser";
        actionMenuItem.enabled = YES;
        TRLog(@"Indexing completed!");
    }];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)buildActionProviders
{
    ////////////////////////////////////////////////////////////////////////////////
    // Setup providers for MenuBar
    ////////////////////////////////////////////////////////////////////////////////
    NSArray *menuBarActions = @[@"File", @"Edit",
                                @"View", @"Find",
                                @"Navigate", @"Editor",
                                @"Product", @"Debug",
                                @"Source Control",
                                @"Window", @"Help"];
    NSMenu *mainMenu = [NSApp mainMenu];
    
    for(NSString *title in menuBarActions) {
        NSMenuItem *item = [mainMenu itemWithTitle:title];
        if(item == nil) continue;
        
        [self.actionIndex registerProvider:[[PGNSMenuActionProvider alloc] initWithMenu:item.submenu]];
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    // TODO: build unit test providers
    ////////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////////////
    // TODO: build code snippet provider
    ////////////////////////////////////////////////////////////////////////////////
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)buildActionProvidersForWorkspace:(IDEWorkspace *)workspace
{
    PGWorkspaceUnitTestsActionProvider *provider = [[PGWorkspaceUnitTestsActionProvider alloc] initWithWorkspace:workspace];
    
    id token =
    [self.actionIndex registerProvider:provider];
    [self.actionIndex updateWithCompletionHandler:^{
        TRLog(@"Index updated with %@", provider);
    }];
    self.providersByWorkspace[XCIDEWorkspaceKey(workspace)] = token;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)buildActionIndexWithCompletionHandler:(PGGeneralCompletionHandler)completionHandler
{
    [self.actionIndex updateWithCompletionHandler:completionHandler];
}

////////////////////////////////////////////////////////////////////////////////
// Review: move to helper/category
////////////////////////////////////////////////////////////////////////////////
- (void)centerWindowInScreen:(NSWindow *)window
{
    NSRect boundsForScreen = [NSScreen mainScreen].frame;
    NSPoint screenCenter   = NSMakePoint(boundsForScreen.size.width / 2,
                                         boundsForScreen.size.height / 2);
    
    NSRect frameForWindow         = window.frame;
    NSRect centeredFrameForWindow = NSMakeRect(screenCenter.x - (frameForWindow.size.width / 2),
                                               screenCenter.y - (frameForWindow.size.height / 2) + (boundsForScreen.size.height / 4),
                                               frameForWindow.size.width,
                                               frameForWindow.size.height);
    [window setFrame:centeredFrameForWindow display:YES];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)registerObservers
{
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationListener:) name:nil object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWorkspaceIndexingCompletedNotification:)
                                                 name:@"IDEIndexDidIndexWorkspaceNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWorkspaceClosedNotification:)
                                                 name:@"_IDEWorkspaceClosedNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNavigationBarEventNotification:)
                                                 name:@"IDENavigableItemCoordinatorDidForgetItemsNotification"
                                               object:nil];
    
    //13/03/2015 14:30:48.116 Xcode[8198]:   Notification: _IDEWorkspaceClosedNotification
    //13/03/2015 13:54:01.412 Xcode[8198]:   Notification: IDENavigableItemCoordinatorDidForgetItemsNotification
    //13/03/2015 14:30:48.113 Xcode[8198]:   Notification: PBXProjectDidCloseNotification
    //13/03/2015 14:30:48.111 Xcode[8198]:   Notification: PBXProjectWillCloseNotification

}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)notificationListener:(NSNotification *)notification
{
    if([[notification name] length] >= 2 && [[[notification name] substringWithRange:NSMakeRange(0, 2)] isEqualTo:@"NS"])
        return;
    else
        NSLog(@"  Notification: %@", [notification name]);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)handleWorkspaceIndexingCompletedNotification:(NSNotification *)notification
{
    IDEIndex *index         = notification.object;
    IDEWorkspace *workspace = index.workspace;
    
    if(TRCheckContainsKey(self.providersByWorkspace, XCIDEWorkspaceKey(workspace)) == NO) {
        [self buildActionProvidersForWorkspace:workspace];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)handleWorkspaceClosedNotification:(NSNotification *)notification
{
    IDEWorkspace *workspace = notification.object;

    NSString *workspaceKey = XCIDEWorkspaceKey(workspace);
    if(TRCheckContainsKey(self.providersByWorkspace, workspaceKey) == YES) {
        [self.actionIndex deregisterProvider:self.providersByWorkspace[workspaceKey]];
        [self.providersByWorkspace removeObjectForKey:workspaceKey];
        [self.actionIndex updateWithCompletionHandler:^{
            TRLog(@"Index update post-removal completed");
        }];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)handleNavigationBarEventNotification:(NSNotification *)notification
{
    
}

@end
