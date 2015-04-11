//
//  XCActionBrowserWindowController.m
//  XCActionBar
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionBarWindowController.h"

#import "XCActionBarPresetStateController.h"
#import "XCActionBarArgumentInputStateController.h"
#import "XCActionBarSearchStateController.h"
#import "XCActionBarCommandProcessor.h"
#import "XCActionBarPresetDataSource.h"
#import "XCActionBarSearchDataSource.h"

#import "XCActionInterface.h"
#import "XCActionPreset.h"
#import "XCSearchService.h"
#import "XCSearchMatchEntry.h"

#import "XCSearchResultCell.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"

typedef BOOL (^XCCommandHandler)(void);
typedef BOOL (^XCRepeatActionHandler)(void);

NSString *const XCActionPresetStateControllerKey  = @"ActionPresetStateController";
NSString *const XCArgumentInputStateControllerKey = @"ArgumentStateController";
NSString *const XCSearchInputStateControllerKey   = @"SearchStateController";

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCActionBarWindowController () <XCActionBarCommandProcessor, NSTextFieldDelegate, NSWindowDelegate>

@property (nonatomic) NSRect frameForEmptySearchResults;
@property (nonatomic) CGFloat searchFieldBottomConstraintConstant;

@property (nonatomic      ) NSDictionary *eventHandlers;
@property (nonatomic      ) NSDictionary *stateControllers;
@property (nonatomic, weak) id<XCActionBarStateController> stateController;

@property (nonatomic) XCActionBarPresetDataSource *presetDataSource;
@property (nonatomic) XCActionBarSearchDataSource *searchDataSource;

@property (weak) IBOutlet NSTextField *searchField;
@property (weak) IBOutlet NSTableView *searchResultsTable;
@property (weak) IBOutlet NSLayoutConstraint *searchFieldBottomConstraint;
@property (weak) IBOutlet NSLayoutConstraint *searchResultsTableHeightConstraint;
@property (weak) IBOutlet NSLayoutConstraint *searchResultsTableBottomConstraint;

@property (nonatomic, copy) XCRepeatActionHandler repeatActionHandler;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCActionBarWindowController

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)initWithBundle:(NSBundle *)bundle searchService:(id<XCSearchService>)searchService
{
    if((self = [super initWithWindowNibName:NSStringFromClass([XCActionBarWindowController class])])) {
        self.searchService = searchService;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)windowDidLoad
{
    [super windowDidLoad];
    
    XCDeclareWeakSelf(weakSelf);
    self.eventHandlers =
    @{
      NSStringFromSelector(@selector(moveUp:)):       [^BOOL { return [weakSelf.stateController handleCursorUpCommand]; } copy],
      NSStringFromSelector(@selector(moveDown:)):     [^BOOL { return [weakSelf.stateController handleCursorDownCommand]; } copy],
      NSStringFromSelector(@selector(insertNewline:)):[^BOOL { return [weakSelf.stateController handleEnterCommand]; } copy],
      NSStringFromSelector(@selector(insertTab:)):    [^BOOL { return [weakSelf.stateController handleTabCommand]; } copy]};

    self.searchDataSource = [[XCActionBarSearchDataSource alloc] initWithSearchService:self.searchService];

    self.stateControllers =
    @{XCActionPresetStateControllerKey: [[XCActionBarPresetStateController alloc] initWithCommandProcessor:self
                                                                                                 tableView:self.searchResultsTable
                                                                                                inputField:self.searchField],
      
      XCSearchInputStateControllerKey:  [[XCActionBarSearchStateController alloc] initWithCommandProcessor:self
                                                                                          searchDataSource:self.searchDataSource
                                                                                                 tableView:self.searchResultsTable
                                                                                                inputField:self.searchField],
      
      XCArgumentInputStateControllerKey:[[XCActionBarArgumentInputStateController alloc] initWithCommandProcessor:self
                                                                                                        tableView:self.searchResultsTable
                                                                                                       inputField:self.searchField]};

    self.searchField.focusRingType = NSFocusRingTypeNone;
    self.searchField.delegate      = self;
    self.searchField.nextResponder = self;
    
    self.searchResultsTable.rowSizeStyle            = NSTableViewRowSizeStyleCustom;
    self.searchResultsTable.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
    self.searchResultsTable.rowHeight               = 50.0;
    
    self.searchResultsTable.target       = self;
    self.searchResultsTable.doubleAction = @selector(processDoubleClickOnSearchResult:);
    
    [self restoreWindowSize];
    [self.window setDelegate:self];
    [self.window makeFirstResponder:self.searchField];
}

#pragma mark - Event Handling

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)cancelOperation:(id)sender
{
    [self close];
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
- (void)keyDown:(NSEvent *)theEvent
{
    XCLog(@"<KeyDown>, <event=%@>", theEvent);
    
    [super keyDown:theEvent];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)processDoubleClickOnSearchResult:(id)sender
{
    [self.stateController handleDoubleClickCommand];
}

#pragma mark - NSWindowDelegate

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)windowDidBecomeKey:(NSNotification *)notification
{
    self.searchFieldBottomConstraintConstant = self.searchFieldBottomConstraint.constant;
    self.frameForEmptySearchResults = self.window.frame;
    
    [self.window makeFirstResponder:self.searchField];

    [self enterActionSearchState];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)windowDidResignKey:(NSNotification *)notification
{
    [self close];
    [self clearSearchResults];
    [self restoreWindowSize];
}

#pragma mark - NSTextDelegate

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)controlTextDidChange:(NSNotification *)notification
{
    NSTextField *textField = notification.object;

//    XCLog(@"<SearchQueryChanged>, <query=%@>", textField.stringValue);

    [self.stateController handleTextInputCommand:textField.stringValue];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
    XCLog(@"<doCommandBySelector>, <cmd=%@>", NSStringFromSelector(command));
    
    NSString *commandKey = NSStringFromSelector(command);
    BOOL handleCommand   = (TRCheckContainsKey(self.eventHandlers, commandKey) == YES);
    if(handleCommand == YES) {
        XCCommandHandler commandHandler = self.eventHandlers[commandKey];
        return commandHandler();
    }
    return handleCommand;
}

#pragma mark - Public Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)clearSearchResults
{
    [self.searchDataSource clearSearchResults];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)executeLastAction
{
    XCExecuteIf(self.repeatActionHandler, self.repeatActionHandler());
}

#pragma mark - Event Action Handlers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)enterActionSearchState
{
    [self.stateController exit];

    self.stateController = self.stateControllers[XCSearchInputStateControllerKey];
    
    [self.stateController enter];

    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)enterActionArgumentStateWithAction:(id<XCActionInterface>)action
{
    [self.stateController exit];

    self.stateController = self.stateControllers[XCArgumentInputStateControllerKey];
    
    [self.stateController enterWithAction:action];
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)enterActionPresetStateWithAction:(id<XCActionInterface>)action
{
    [self.stateController exit];
    
    self.stateController = self.stateControllers[XCActionPresetStateControllerKey];
    
    [self.stateController enterWithAction:action];
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)selectNextSearchResult
{
    return [self.stateController handleCursorDownCommand];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)selectPreviousSearchResult
{
    return [self.stateController handleCursorUpCommand];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeAction:(id<XCActionInterface>)action
{
    BOOL executed = [action executeWithContext:self.context];

    XCReturnFalseUnless(executed);

    XCDeclareWeakSelf(weakSelf);
    [self close];
    
    self.repeatActionHandler = ^{ return [action executeWithContext:weakSelf.context]; };
    
    return executed;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeAction:(id<XCActionInterface>)action withArguments:(NSString *)arguments
{
    BOOL validated = [action validateArgumentsWithContext:self.context arguments:arguments];
    if(validated == NO) return NO;
    
    BOOL executed = [action executeWithContext:self.context arguments:arguments];
    XCReturnFalseUnless(executed);

    XCDeclareWeakSelf(weakSelf);
    [self close];
    
    self.repeatActionHandler = ^{ return [action executeWithContext:weakSelf.context
                                                          arguments:arguments];
    };
    
    return executed;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeActionPreset:(id<XCActionPreset>)preset
{
    BOOL executed = [preset executeWithContext:self.context];
    XCReturnFalseUnless(executed);

    XCDeclareWeakSelf(weakSelf);
    [self close];

    self.repeatActionHandler = ^{ return [preset executeWithContext:weakSelf.context]; };

    return executed;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)cancel
{
    [self cancelOperation:self];
    return YES;
}

#pragma mark - Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)resizeWindowToAccomodateSearchResults
{
    if([self.searchDataSource numberOfResults] > 0) {
        [[self.searchResultsTable animator] setAlphaValue:1.0];
        
        self.searchResultsTable.hidden = NO;
        self.searchResultsTableBottomConstraint.constant = 10.0;
        self.searchResultsTableHeightConstraint.constant = 250.0;
        
        [self.searchField layoutSubtreeIfNeeded];
    }
    else [self restoreWindowSize];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)restoreWindowSize
{
    [[self.searchResultsTable animator] setAlphaValue:0.0];
    
    self.searchResultsTable.hidden = YES;
    self.searchResultsTableBottomConstraint.constant = 0.0;
    self.searchResultsTableHeightConstraint.constant = 0.0;
    
    [self.window.contentView layoutSubtreeIfNeeded];
}

@end
