//
//  XCActionBar.m
//  XCActionBar
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionBar.h"
#import "XCActionBarConfiguration.h"
#import "XCIDEContext.h"
#import "XCIDEHelper.h"

#import "XCActionIndex.h"
#import "XCHotKeyListener.h"
#import "XCSearchService.h"
#import "XCPartialMatchSearchStrategy.h"
#import "XCFuzzySearchStrategy.h"

#import "XCNSMenuActionProvider.h"
#import "XCWorkspaceUnitTestsActionProvider.h"
#import "XCCodeSnippetProvider.h"
#import "XCCustomActionProvider.h"

#import "XCActions.h"
#import "XCTextSelectionStorage.h"

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

@property (nonatomic) NSBundle     *bundle;
@property (nonatomic) id<XCActionBarConfiguration> configuration;

@property (nonatomic) XCIDEContext *context;

@property (nonatomic) id<XCActionIndex    > actionIndex;
@property (nonatomic) id<XCSearchService> searchService;

@property (nonatomic) NSMutableDictionary *providersByWorkspace;

@property (nonatomic) XCActionBarWindowController *windowController;
@property (nonatomic) NSMenuItem                  *actionBarMenuItem;

@property (nonatomic) NSArray *hotKeyListeners;

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
            XCLog(@"Pluging Loaded!");
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
        self.windowController = [[XCActionBarWindowController alloc] initWithBundle:self.bundle
                                                                      searchService:self.searchService];
        self.windowController.context = self.context;
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

//#define XCSearchStrategyClass XCFuzzySearchStrategy
#define XCSearchStrategyClass XCPartialMatchSearchStrategy
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)performInitialization
{
    NSDictionary *configuration = [NSDictionary dictionaryWithContentsOfURL:[self.bundle URLForResource:@"XCActionBarConfiguration" withExtension:@"plist"]];
    self.configuration = [[XCActionBarConfiguration alloc] initWithDictionary:configuration];
    self.context       = [[XCIDEContext alloc] init];
    self.actionIndex   = [[XCActionIndex alloc] init];
    self.searchService = [[XCSearchService alloc] initWithIndex:self.actionIndex
                                                       strategy:[[XCSearchStrategyClass alloc] init]];
    
    XCDeclareWeakSelf(weakSelf);

    XCLog(@"Indexing actions ...");

    [self builActionBarMenuItem];
    [self buildActionProviders];
    [self buildActionIndexWithCompletionHandler:^{
        weakSelf.actionBarMenuItem.title   = @"Action Bar";
        weakSelf.actionBarMenuItem.enabled = YES;
        [weakSelf buildRepeatLastActionMenuItem];
        [weakSelf setupHotKeys];
        XCLog(@"Indexing completed!");
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
    NSArray *menuBarItemsSupportingIndexUpdates = @[@"Editor"];
    
    NSMenu *mainMenu = [NSApp mainMenu];
    
    for(NSString *title in menuBarActions) {
        NSMenuItem *item = [mainMenu itemWithTitle:title];
        if(item == nil) continue;
        
        XCNSMenuActionProvider *provider = [[XCNSMenuActionProvider alloc] initWithMenu:item.submenu];
        if([menuBarItemsSupportingIndexUpdates containsObject:title]) {
            provider.respondToMenuChanges = YES;
        }
        [self.actionIndex registerProvider:provider];
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
    XCTextSelectionStorage *textSelectionStorage = [[XCTextSelectionStorage alloc] init];
    
    NSMutableArray *textActions = @[
                                    // Prefix/Suffix
                                    [[XCAddPrefixToLinesAction alloc] init],
                                    [[XCAddSuffixToLinesAction alloc] init],
                                    
                                    [[XCAddPrefixToTextAction alloc] init],
                                    [[XCAddSuffixToTextAction alloc] init],
                                    
                                    // Column selection mode
                                    [[XCColumnSelectionModeAction alloc] init],
                                    
                                    [[XCMoveSelectionHereAction alloc] initWithTextSelectionStorage:textSelectionStorage],
                                    
                                    // Duplicate/Delete Lines
                                    [[XCDeleteBlankLinesAction alloc] init],
                                    [[XCDeleteLineAction alloc] init],
                                    [[XCDuplicateLineAction alloc] init],
                                    
                                    [[XCSaveTextSelectionAction alloc] initWithTextSelectionStorage:textSelectionStorage],
                                    [[XCLoadTextSelectionAction alloc] initWithTextSelectionStorage:textSelectionStorage],
                                    [[XCClearTextSelectionAction alloc] initWithTextSelectionStorage:textSelectionStorage],
                                    // Sort Selection
                                    [[XCSortSelectionAction alloc] initWithSortOrder:NSOrderedAscending],
                                    [[XCSortSelectionAction alloc] initWithSortOrder:NSOrderedDescending],
                                    
                                    // Sort Contents
                                    [[XCSortContentsAction alloc] initWithSortOrder:NSOrderedAscending],
                                    [[XCSortContentsAction alloc] initWithSortOrder:NSOrderedDescending],
                                    
                                    // Split and Join
                                    [[XCSplitSelectionIntoLinesAction alloc] init],
                                    [[XCJoinLinesAction alloc] init],
                                    
                                    // Trim Operations
                                    [[XCTrimWhitespaceAction alloc] initWithBehavior:XCTrimWhitespaceBehaviorLeading],
                                    [[XCTrimWhitespaceAction alloc] initWithBehavior:XCTrimWhitespaceBehaviorTrailing],
                                    [[XCTrimWhitespaceAction alloc] initWithBehavior:XCTrimWhitespaceBehaviorLeadingAndTrailing],
                                    
                                    // Generator Actions
                                    [[XCGUIDGeneratorAction alloc] init],
                                    
                                    ].mutableCopy;

    NSArray *surroundWithActionSpecs = [NSArray arrayWithContentsOfURL:[self.bundle URLForResource:@"XCSurroundWithActions" withExtension:@"plist"]];
    
    for(NSDictionary *spec in surroundWithActionSpecs) {
        [textActions addObject:[[XCSurroundWithAction alloc] initWithSpec:spec]];
        [textActions addObject:[[XCSurroundLineWithAction alloc] initWithSpec:spec]];
    }
    
    [textActions addObject:[[XCCopyActiveDocumentPathAction alloc] initWithFormat:XCDocumentFilePathFormatPOSIX]];
    [textActions addObject:[[XCCopyActiveDocumentPathAction alloc] initWithFormat:XCDocumentFilePathFormatTerminal]];
    [textActions addObject:[[XCCopyActiveDocumentPathAction alloc] initWithFormat:XCDocumentFilePathFormatURL]];
    
    [textActions addObject:[[XCCopyActiveDocumentDirectoryAction alloc] initWithFormat:XCDocumentFilePathFormatPOSIX]];
    [textActions addObject:[[XCCopyActiveDocumentDirectoryAction alloc] initWithFormat:XCDocumentFilePathFormatTerminal]];
    [textActions addObject:[[XCCopyActiveDocumentDirectoryAction alloc] initWithFormat:XCDocumentFilePathFormatURL]];
    
    [textActions addObject:[[XCOpenActiveDocumentPathInTerminalAction alloc] initWithPrioritizedTerminalApplicationList:self.configuration.supportedTerminalApplications]];
    
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
        XCLog(@"Index updated with %@", provider);
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
// Review: move to helper/category - also need to completely change the approach
////////////////////////////////////////////////////////////////////////////////
- (void)centerWindowInScreen:(NSWindow *)window
{
    NSRect boundsForScreen = [NSScreen mainScreen].frame;
    NSPoint screenCenter   = NSMakePoint(boundsForScreen.size.width / 2,
                                         boundsForScreen.size.height / 2);
    
    NSRect frameForWindow = window.frame;
    CGFloat offset        = (NSHeight(frameForWindow) - 42.0) / 2.0;
    
    NSRect centeredFrameForWindow = NSMakeRect(screenCenter.x - (frameForWindow.size.width / 2),
                                               screenCenter.y - (frameForWindow.size.height / 2) + (boundsForScreen.size.height / 4) - offset,
                                               frameForWindow.size.width,
                                               frameForWindow.size.height);
    centeredFrameForWindow = NSOffsetRect(centeredFrameForWindow, boundsForScreen.origin.x, boundsForScreen.origin.y);
    [window setFrame:centeredFrameForWindow display:YES];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)setupHotKeys
{
    if(TRCheckIsEmpty(self.configuration.shortcuts) == YES) return;
    
    NSMutableArray *hotKeyListeners = [NSMutableArray array];
    NSDictionary   *shortcuts       = self.configuration.shortcuts;

    BOOL (^XCSetupHotKeyListener)(NSDictionary *configuration, id target, SEL action) = ^(NSDictionary *configuration, id target, SEL action) {

        NSError *error = nil;
        if([XCHotKeyListener validateConfiguration:configuration error:&error] == NO) {
            XCLog(@"[ERROR] <SetupHotKeys>, <failure>, <error=%@>", error);

            return NO;
        }

        XCHotKeyListener *listener = [[XCHotKeyListener alloc] initWithConfiguration:configuration target:target action:action];
        [hotKeyListeners addObject:listener];
        
        return YES;
    };
    
    XCSetupHotKeyListener(shortcuts[@"XCActionBarHotKey"], self, @selector(presentOrDismissActionSearchBar));
    XCSetupHotKeyListener(shortcuts[@"XCRepeatLastActionHotKey"], self, @selector(repeatLastAction));
    
    self.hotKeyListeners = hotKeyListeners.copy;
    
    [self.hotKeyListeners makeObjectsPerformSelector:@selector(startListening)];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define NSFlagsChangedMaskOff (1 << 8) // need to figure out what values I actually need to get this
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
            XCLog(@"Index update post-removal completed");
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
    self.context.configuration      = self.configuration;
    self.context.sourceCodeEditor   = [XCIDEHelper currentEditor];
    self.context.editorDocument     = [XCIDEHelper currentDocument];
    self.context.workspaceDocument  = [XCIDEHelper currentWorkspaceDocument];
    self.context.sourceCodeDocument = [XCIDEHelper currentSourceCodeDocument];
    self.context.sourceCodeTextView = [XCIDEHelper currentSourceCodeTextView];
}

@end
