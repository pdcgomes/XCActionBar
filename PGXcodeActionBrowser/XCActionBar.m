//
//  XCActionBar.m
//  XCActionBar
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionBar.h"
#import "XCIDEContext.h"
#import "XCIDEHelper.h"

#import "XCActionIndex.h"
#import "XCSearchService.h"

#import "XCNSMenuActionProvider.h"
#import "XCWorkspaceUnitTestsActionProvider.h"
#import "XCCodeSnippetProvider.h"
#import "XCCustomActionProvider.h"

#import "XCAddPrefixToLinesAction.h"
#import "XCAddSuffixToLinesAction.h"
#import "XCDeleteLineAction.h"
#import "XCDuplicateLineAction.h"
#import "XCSortContentsAction.h"
#import "XCSortSelectionAction.h"
#import "XCSurroundWithAction.h"
#import "XCSurroundLineWithAction.h"

#import "XCActionBarWindowController.h"

#import "IDECodeSnippet.h"
#import "IDECodeSnippetRepository.h"
#import "IDEIndex.h"
#import "IDEWorkspace.h"
#import "DVTFilePath.h"

#define XCIDEWorkspaceKey(_workspace_) [_workspace_.representingFilePath pathString]

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
static XCActionBar *sharedPlugin;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCActionBar ()

@property (nonatomic, strong, readwrite) NSBundle *bundle;

@property (nonatomic, strong) XCIDEContext *context;

@property (nonatomic, strong) id<PGActionIndex  > actionIndex;
@property (nonatomic, strong) id<XCSearchService> searchService;

@property (nonatomic, strong) NSMutableDictionary *providersByWorkspace;

@property (nonatomic, strong) XCActionBarWindowController *windowController;
@property (nonatomic, strong) NSMenuItem *actionBarMenuItem;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCActionBar

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
- (void)presentOrDismissActionSearchBar
{
    if([[self.windowController window] isKeyWindow] == YES) {
        [self.windowController close];
    }
    else [self presentActionSearchBar];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)presentActionSearchBar
{
    if(self.windowController == nil) {
        self.windowController = [[XCActionBarWindowController alloc] initWithBundle:self.bundle];
        // REVIEW: initWithBundle:searchService:
        self.windowController.context       = self.context;
        self.windowController.searchService = self.searchService;
    }
    
    [self updateContext];
    [self centerWindowInScreen:[self.windowController window]];
    [self.windowController showWindow:self];
    [self.windowController becomeFirstResponder];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)repeatLastAction
{
    [self updateContext];
    [self.windowController executeLastAction];
}

#pragma mark - Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)performInitialization
{
    self.context       = [[XCIDEContext alloc] init];
    self.actionIndex   = [[XCActionIndex alloc] init];
    self.searchService = [[XCSearchService alloc] initWithIndex:self.actionIndex
                                                       strategy:nil];
    
    RTVDeclareWeakSelf(weakSelf);

    TRLog(@"Indexing actions ...");

    [self builActionBarMenuItem];
    [self buildActionProviders];
    [self buildActionIndexWithCompletionHandler:^{
        weakSelf.actionBarMenuItem.title   = @"Action Bar";
        weakSelf.actionBarMenuItem.enabled = YES;
        [weakSelf buildRepeatLastActionMenuItem];
        TRLog(@"Indexing completed!");
    }];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)builActionBarMenuItem
{
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Window"];
    if(menuItem == nil) return;
    
    [menuItem.submenu addItem:[NSMenuItem separatorItem]];
    self.actionBarMenuItem = [[NSMenuItem alloc] initWithTitle:@"Action Bar (indexing...)"
                                                        action:@selector(presentActionSearchBar)
                                                 keyEquivalent:@"8"];
    self.actionBarMenuItem.keyEquivalentModifierMask = (NSCommandKeyMask | NSShiftKeyMask);
    self.actionBarMenuItem.target  = self;
    self.actionBarMenuItem.enabled = NO;
    
    [menuItem.submenu insertItem:self.actionBarMenuItem
                         atIndex:[menuItem.submenu indexOfItemWithTitle:@"Bring All to Front"] - 1];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)buildRepeatLastActionMenuItem
{
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Window"];
    if(menuItem == nil) return;
    
    NSMenuItem *repeatCommandMenuItem = [[NSMenuItem alloc] initWithTitle:@"Repeat last action"
                                                                   action:@selector(repeatLastAction)
                                                            keyEquivalent:@"7"];

    repeatCommandMenuItem.keyEquivalentModifierMask = (NSCommandKeyMask | NSAlternateKeyMask);
    repeatCommandMenuItem.target  = self;
    repeatCommandMenuItem.enabled = YES;

    [menuItem.submenu insertItem:repeatCommandMenuItem
                         atIndex:[menuItem.submenu indexOfItemWithTitle:@"Action Bar"]];

}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)buildActionProviders
{
    ////////////////////////////////////////////////////////////////////////////////
    // Setup providers for MenuBar
    ////////////////////////////////////////////////////////////////////////////////
    NSArray *menuBarActions = @[@"File",
                                @"Edit",
                                @"View",
                                @"Find",
                                @"Navigate",
                                @"Editor",
                                @"Product",
                                @"Debug",
                                @"Source Control",
                                @"Window",
                                @"Help"];
    NSMenu *mainMenu = [NSApp mainMenu];
    
    for(NSString *title in menuBarActions) {
        NSMenuItem *item = [mainMenu itemWithTitle:title];
        if(item == nil) continue;
        
        [self.actionIndex registerProvider:[[XCNSMenuActionProvider alloc] initWithMenu:item.submenu]];
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Code Snippets
    ////////////////////////////////////////////////////////////////////////////////
    IDECodeSnippetRepository *codeSnippetRepository = [NSClassFromString(@"IDECodeSnippetRepository") performSelector:@selector(sharedRepository)];
    XCCodeSnippetProvider *codeSnippetProvider      = [[XCCodeSnippetProvider alloc] initWithCodeSnippetRepository:codeSnippetRepository];
    
    [self.actionIndex registerProvider:codeSnippetProvider];

    ////////////////////////////////////////////////////////////////////////////////
    // Built-in Actions
    // TODO: build menu items for custom actions and bind them to the provider
    ////////////////////////////////////////////////////////////////////////////////
    NSMutableArray *textActions = @[
                                    // Prefix/Suffix
                                    [[XCAddPrefixToLinesAction alloc] init],
                                    [[XCAddSuffixToLinesAction alloc] init],
                                    // Duplicate/Delete Lines
                                    [[XCDeleteLineAction alloc] init],
                                    [[XCDuplicateLineAction alloc] init],
                                    
                                    // Sort Selection
                                    [[XCSortSelectionAction alloc] initWithSortOrder:NSOrderedAscending],
                                    [[XCSortSelectionAction alloc] initWithSortOrder:NSOrderedDescending],
                                    
                                    // Sort Contents
                                    [[XCSortContentsAction alloc] initWithSortOrder:NSOrderedAscending],
                                    [[XCSortContentsAction alloc] initWithSortOrder:NSOrderedDescending],
                                    
                                    ].mutableCopy;

    NSArray *surroundWithActionSpecs = [NSArray arrayWithContentsOfURL:[self.bundle URLForResource:@"XCSurroundWithActions" withExtension:@"plist"]];
    
    for(NSDictionary *spec in surroundWithActionSpecs) {
        [textActions addObject:[[XCSurroundWithAction alloc] initWithSpec:spec]];
        [textActions addObject:[[XCSurroundLineWithAction alloc] initWithSpec:spec]];
    }
    
    XCCustomActionProvider *builtInTextActionsProvider = [[XCCustomActionProvider alloc] initWithCategory:@"Built-in"
                                                                                                    group:@"Text"
                                                                                                  actions:textActions.copy
                                                                                                  context:self.context];
    [self.actionIndex registerProvider:builtInTextActionsProvider];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)buildActionProvidersForWorkspace:(IDEWorkspace *)workspace
{
    XCWorkspaceUnitTestsActionProvider *provider = [[XCWorkspaceUnitTestsActionProvider alloc] initWithWorkspace:workspace];
    
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
#define NSFlagsChangedMaskOff (1 << 8) // need to figure out what values I actually need to get this
- (void)registerObservers
{
    // 63 fn L
    
    // 55 cmd L
    // 54 cmd R

    // 58 opt L
    // 61 opt R

    // 59 ctrl L
    // 56 shift L
    // 60 shift R
    
//    NSAlphaShiftKeyMask         = 1 << 16,
//    NSShiftKeyMask              = 1 << 17,
//    NSControlKeyMask            = 1 << 18,
//    NSAlternateKeyMask          = 1 << 19,
//    NSCommandKeyMask            = 1 << 20,
//    NSNumericPadKeyMask         = 1 << 21,
//    NSHelpKeyMask               = 1 << 22,
//    NSFunctionKeyMask           = 1 << 23,

    NSArray *hotKeyCodes               = @[@(54), @(55)];
    NSUInteger      requiredKeyPresses = 2;
    NSTimeInterval  repeatInterval     = 0.100;
    
    __block NSUInteger hotKeyPressCount = 0;
    __block NSTimeInterval keyDownTS    = 0;
    __block BOOL hotKeyDepressed        = false;
    
    void(^ResetHotKeyState)(void) = ^ {
        hotKeyDepressed  = false;
        hotKeyPressCount = 0;
        keyDownTS        = 0;
    };
    
    [NSEvent addLocalMonitorForEventsMatchingMask:(NSFlagsChangedMask) handler:^NSEvent *(NSEvent *event) {
//        TRLog(@"<EventMonitor>, <type=%@>, <keyCode=%@>, <e=%@>", @(event.type), @(event.keyCode), event);

        BOOL hotKeyPressed = (event.keyCode == [hotKeyCodes[0] unsignedCharValue] ||
                              event.keyCode == [hotKeyCodes[1] unsignedCharValue]);
        if(hotKeyPressed == NO) {
            // cancel hot key
            TRLog(@"<cmd>");
            ResetHotKeyState();
            return event;
        }
        
        if(event.modifierFlags == NSFlagsChangedMaskOff) {
            hotKeyDepressed = false;
            
            NSTimeInterval interval = (event.timestamp - keyDownTS);
            if(interval <= repeatInterval) hotKeyPressCount++;
            else ResetHotKeyState();
            
            if(hotKeyPressCount >= requiredKeyPresses) {
                ResetHotKeyState();
                [self presentOrDismissActionSearchBar];
            }
            
        }
        else {
//            TRLog(@"key up <ts=%@>", @(interval));
            hotKeyDepressed = true;
            keyDownTS = event.timestamp;
        }
        return event;
    }];
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

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)updateContext
{
    self.context.workspaceDocument  = [XCIDEHelper currentWorkspaceDocument];
    self.context.sourceCodeDocument = [XCIDEHelper currentSourceCodeDocument];
    self.context.sourceCodeTextView = [XCIDEHelper currentSourceCodeTextView];
}

@end
