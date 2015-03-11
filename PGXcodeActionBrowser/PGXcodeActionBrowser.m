//
//  PGXcodeActionBrowser.m
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "PGXcodeActionBrowser.h"

#import "PGActionBrowserWindowController.h"
#import "PGTestCaseActionProvider.h"

#import "PGNSMenuActionProvider.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
static PGXcodeActionBrowser *sharedPlugin;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface PGXcodeActionBrowser()

@property (nonatomic, strong, readwrite) NSBundle *bundle;

@property (nonatomic, strong) NSMutableArray   *providers;
@property (nonatomic, strong) dispatch_queue_t indexerQueue;

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
        // reference to plugin's bundle, for resource access
        self.bundle = plugin;
        self.indexerQueue = dispatch_queue_create("org.pedrogomes.XcodeActionBrowser.ActionIndexer", DISPATCH_QUEUE_CONCURRENT);
        
        ////////////////////////////////////////////////////////////////////////////////
        // Create menu items, initialize UI, etc.
        ////////////////////////////////////////////////////////////////////////////////
        NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Window"];
        if(menuItem) {
            [menuItem.submenu addItem:[NSMenuItem separatorItem]];
            NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Action Browser (indexing...)"
                                                                    action:@selector(openActionBrowser)
                                                             keyEquivalent:@""];
            actionMenuItem.target  = self;
            actionMenuItem.enabled = NO;

            [menuItem.submenu addItem:actionMenuItem];
         
            TRLog(@"Indexing actions ...");
            [self buildActionProviders];
            [self buildActionIndexWithCompletionHandler:^{
                actionMenuItem.title   = @"Action Browser";
                actionMenuItem.enabled = YES;
                TRLog(@"Indexing completed!");
            }];
        }
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
    
    NSWindow *window = [self.windowController window];
    
    NSRect boundsForScreen = [NSScreen mainScreen].frame;
    NSPoint screenCenter   = NSMakePoint(boundsForScreen.size.width / 2,
                                         boundsForScreen.size.height / 2);
    
    NSRect frameForWindow         = window.frame;
    NSRect centeredFrameForWindow = NSMakeRect(screenCenter.x - (frameForWindow.size.width / 2),
                                               screenCenter.y - (frameForWindow.size.height / 2),
                                               frameForWindow.size.width,
                                               frameForWindow.size.height);
    [window setFrame:centeredFrameForWindow display:YES];
    
    [[self.windowController window] makeKeyAndOrderFront:self];
//    self.window = [[PGActionBrowserWindowController alloc] initWithWindowNibPath:windowNibPath owner:nil];
//    [self.window showWindow:self];
    
}

#pragma mark - Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)buildActionProviders
{
    NSArray *menuBarActions = @[@"File", @"Edit",
                                @"View", @"Find",
                                @"Navigate", @"Editor",
                                @"Product", @"Debug",
                                @"Source Control",
                                @"Window", @"Help"];
    
    NSMenu *mainMenu = [NSApp mainMenu];
    self.providers = [NSMutableArray array];
    
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

@end
