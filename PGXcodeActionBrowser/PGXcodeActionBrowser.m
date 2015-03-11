//
//  PGXcodeActionBrowser.m
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "PGXcodeActionBrowser.h"

#import "PGSearchService.h"

#import "PGNSMenuActionProvider.h"
#import "PGTestCaseActionProvider.h"

#import "PGActionBrowserWindowController.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
static PGXcodeActionBrowser *sharedPlugin;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface PGXcodeActionBrowser()

@property (nonatomic, strong, readwrite) NSBundle *bundle;

@property (nonatomic, strong) NSMutableArray   *providers;
@property (nonatomic, strong) dispatch_queue_t indexerQueue;

@property (nonatomic, strong) id<PGSearchService> searchService;

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
        
        ////////////////////////////////////////////////////////////////////////////////
        // General initialization
        ////////////////////////////////////////////////////////////////////////////////
        [self performInitialization];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// Sample Action, for menu item:
- (void)openActionBrowser
{
    if(self.windowController == nil) {
        self.windowController = [[PGActionBrowserWindowController alloc] initWithBundle:self.bundle];
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
    self.indexerQueue  = dispatch_queue_create("org.pedrogomes.XcodeActionBrowser.ActionIndexer", DISPATCH_QUEUE_CONCURRENT);
    self.searchService = [[PGSearchService alloc] init];
    
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
                                                            action:@selector(openActionBrowser)
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
    self.providers = [NSMutableArray array];
    
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
        
        [self.providers addObject:[[PGNSMenuActionProvider alloc] initWithMenu:item.submenu]];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)buildActionIndexWithCompletionHandler:(PGGeneralCompletionHandler)completionHandler
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
                                               screenCenter.y - (frameForWindow.size.height / 2),
                                               frameForWindow.size.width,
                                               frameForWindow.size.height);
    [window setFrame:centeredFrameForWindow display:YES];
}

@end
