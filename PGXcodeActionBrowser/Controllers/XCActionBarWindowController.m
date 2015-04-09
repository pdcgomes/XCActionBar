//
//  XCActionBrowserWindowController.m
//  XCActionBar
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionBarWindowController.h"

#import "XCActionBarArgumentInputStateCommandHandler.h"
#import "XCActionBarSearchStateCommandHandler.h"
#import "XCActionBarCommandProcessor.h"
#import "XCActionInterface.h"
#import "XCActionPreset.h"
#import "XCSearchService.h"
#import "XCSearchMatchEntry.h"

#import "XCSearchResultCell.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"

typedef BOOL (^XCCommandHandler)(void);
typedef BOOL (^XCRepeatActionHandler)(void);

NSString *const XCSearchInputHandlerKey   = @"SearchHandler";
NSString *const XCArgumentInputHandlerKey = @"ArgumentHandler";

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCActionBarWindowController () <XCActionBarCommandProcessor, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, NSWindowDelegate>

@property (nonatomic) NSRect frameForEmptySearchResults;
@property (nonatomic) CGFloat searchFieldBottomConstraintConstant;

@property (nonatomic      ) NSDictionary *eventHandlers;
@property (nonatomic      ) NSDictionary *commandHandlers;
@property (nonatomic, weak) id<XCActionBarCommandHandler> commandHandler;

@property (weak) IBOutlet NSTextField *searchField;
@property (weak) IBOutlet NSTableView *searchResultsTable;
@property (weak) IBOutlet NSLayoutConstraint *searchFieldBottomConstraint;
@property (weak) IBOutlet NSLayoutConstraint *searchResultsTableHeightConstraint;
@property (weak) IBOutlet NSLayoutConstraint *searchResultsTableBottomConstraint;

@property (nonatomic) NSArray *searchResults;

@property (nonatomic, copy) XCRepeatActionHandler repeatActionHandler;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCActionBarWindowController

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)initWithBundle:(NSBundle *)bundle
{
    if((self = [super initWithWindowNibName:NSStringFromClass([XCActionBarWindowController class])])) {
        
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)windowDidLoad
{
    [super windowDidLoad];
    
    XCDeclareWeakSelf(weakSelf);
    self.eventHandlers = @{
                           NSStringFromSelector(@selector(moveUp:)):       [^BOOL { return [weakSelf.commandHandler handleCursorUpCommand]; } copy],
                           NSStringFromSelector(@selector(moveDown:)):     [^BOOL { return [weakSelf.commandHandler handleCursorDownCommand]; } copy],
                           NSStringFromSelector(@selector(insertNewline:)):[^BOOL { return [weakSelf.commandHandler handleEnterCommand]; } copy],
                           NSStringFromSelector(@selector(insertTab:)):    [^BOOL { return [weakSelf.commandHandler handleTabCommand]; } copy]
                           };

    self.commandHandlers = @{XCSearchInputHandlerKey:   [[XCActionBarSearchStateCommandHandler alloc] initWithCommandProcessor:self],
                             XCArgumentInputHandlerKey: [[XCActionBarArgumentInputStateCommandHandler alloc] initWithCommandProcessor:self]};

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
    [self.commandHandler handleDoubleClickCommand];
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
    [self restoreLastSearchAndSelection];
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

    [self.commandHandler handleTextInputCommand:textField.stringValue];
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

#pragma mark - NSTableViewDataSource

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
{
    return self.searchResults.count;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return self.searchResults[rowIndex];
}

#pragma mark - NSTableViewDelegate

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    XCSearchResultCell *cell = [tableView makeViewWithIdentifier:NSStringFromClass([XCSearchResultCell class]) owner:self];
    
    id<XCSearchMatchEntry> searchMatch = self.searchResults[row];
    id<XCActionInterface > action      = searchMatch.action;

    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:TRSafeString(action.title)];
    
    [title addAttribute:NSForegroundColorAttributeName
                  value:(action.enabled ? [NSColor blackColor] : [NSColor darkGrayColor])
                  range:NSMakeRange(0, title.length)];
    
    for(NSValue *rangeValue in searchMatch.rangesForMatch) {
        [title addAttributes:@{NSBackgroundColorAttributeName:[NSColor colorWithCalibratedRed:1.000 green:1.000 blue:0.519 alpha:0.250],
                               NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                               NSUnderlineColorAttributeName: [NSColor yellowColor]}
                       range:rangeValue.rangeValue];
    }
    
    cell.textField.allowsEditingTextAttributes = YES;
    
    cell.textField.attributedStringValue = title;
    cell.hintTextField.stringValue       = TRSafeString(action.hint);
    
    if([action acceptsArguments] == YES) {
//        NSString *summaryWithMarker = [NSString stringWithFormat:@"%@ %@", @"\uf11c", TRSafeString(action.subtitle)];
//        NSMutableAttributedString *summary = [[NSMutableAttributedString alloc] initWithString:summaryWithMarker];
//        [summary addAttributes:@{NSFontAttributeName: XCFontAwesomeWithSize(12.0)}
//                         range:NSMakeRange(0, 1)];
//        cell.subtitleTextField.allowsEditingTextAttributes = YES;
//        cell.subtitleTextField.attributedStringValue       = summary;
        
        cell.subtitleTextField.stringValue = [NSString stringWithFormat:@"%@ %@", @"\u21e5", TRSafeString(action.subtitle)];
    }
    else cell.subtitleTextField.stringValue   = TRSafeString(action.subtitle);
    
    
    return cell;
}

#pragma mark - Public Methods


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)updateSearchResults:(NSArray *)results
{
//    XCLog(@"<UpdatedSearchResults>, <results=%@>", results);
    
    self.searchResults = results;
    [self.searchResultsTable reloadData];
    
    if(TRCheckIsEmpty(self.searchResultsTable) == NO) {
        [self selectSearchResultAtIndex:0];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)clearSearchResults
{
    [self updateSearchResults:@[]];
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
    [self.commandHandler exit];
    
    self.commandHandler = self.commandHandlers[XCSearchInputHandlerKey];
    [self.commandHandler enterWithInputControl:self.searchField];
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)enterActionArgumentState
{
    [self.commandHandler exit];

    self.commandHandler = self.commandHandlers[XCArgumentInputHandlerKey];
    [self.commandHandler enterWithInputControl:self.searchField];
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)enterActionTemplateState
{
    return NO;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)searchActionWithExpression:(NSString *)query
{
    [self performSearchWithExpression:query];
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)selectNextSearchResult
{
//    XCLog(@"<selectNextSearchResult>");
    
    NSInteger rowCount      = [self.searchResultsTable numberOfRows];
    NSInteger selectedIndex = self.searchResultsTable.selectedRow;
    NSInteger indexToSelect = (selectedIndex == -1 ? 0 : (selectedIndex + 1 < rowCount ? selectedIndex + 1 : 0));
    
    [self selectSearchResultAtIndex:indexToSelect];

    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)selectPreviousSearchResult
{
//    XCLog(@"<selectPreviousSearchResult>");
    
    NSInteger rowCount      = [self.searchResultsTable numberOfRows];
    NSInteger selectedIndex = self.searchResultsTable.selectedRow;
    NSInteger indexToSelect = (selectedIndex == -1 ? rowCount - 1 : (selectedIndex - 1 >= 0 ? selectedIndex - 1 : rowCount - 1));
    
    [self selectSearchResultAtIndex:indexToSelect];

    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeSelectedAction
{
    NSInteger selectedIndex = self.searchResultsTable.selectedRow;
    if(selectedIndex == -1) return NO;
    
    id<XCSearchMatchEntry> searchMatch    = self.searchResults[selectedIndex];
    id<XCActionInterface > selectedAction = searchMatch.action;
    BOOL executed = [selectedAction executeWithContext:self.context];

    XCReturnFalseUnless(executed);

    XCDeclareWeakSelf(weakSelf);
    [self close];
    
    self.repeatActionHandler = ^{ return [selectedAction executeWithContext:weakSelf.context]; };
    
    return executed;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeSelectedActionWithArguments:(NSString *)arguments
{
    NSInteger selectedIndex = self.searchResultsTable.selectedRow;
    if(selectedIndex == -1) return NO;
    
    id<XCSearchMatchEntry> searchMatch    = self.searchResults[selectedIndex];
    id<XCActionInterface > selectedAction = searchMatch.action;
    BOOL validated = [selectedAction validateArgumentsWithContext:self.context arguments:arguments];
    if(validated == NO) return NO;
    
    BOOL executed = [selectedAction executeWithContext:self.context arguments:arguments];
    XCReturnFalseUnless(executed);

    XCDeclareWeakSelf(weakSelf);
    [self close];
    
    self.repeatActionHandler = ^{ return [selectedAction executeWithContext:weakSelf.context
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
- (BOOL)autoCompleteWithSelectedAction
{
    NSInteger selectedIndex = self.searchResultsTable.selectedRow;
    if(selectedIndex == -1) return YES;

    id<XCActionInterface> selectedAction = self.searchResults[selectedIndex];

    [self.searchField setStringValue:selectedAction.title];
    [self performSearchWithExpression:selectedAction.title];
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)cancel
{
    [self cancelOperation:self];
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id<XCActionInterface>)retrieveSelectedAction
{
    NSInteger selectedIndex = self.searchResultsTable.selectedRow;
    if(selectedIndex == -1) return nil;
    
    id<XCSearchMatchEntry> searchMatch = self.searchResults[selectedIndex];
    return searchMatch.action;
}

#pragma mark - Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)selectSearchResultAtIndex:(NSInteger)indexToSelect
{
    [self.searchResultsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:indexToSelect]
                         byExtendingSelection:NO];
    [self.searchResultsTable scrollRowToVisible:indexToSelect];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)resizeWindowToAccomodateSearchResults
{
    if(TRCheckIsEmpty(self.searchResults) == NO) {
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

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)restoreLastSearchAndSelection
{
    XCReturnUnless(TRCheckIsEmpty(self.searchField.stringValue) == NO);
    
    [self performSearchWithExpression:self.searchField.stringValue];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)performSearchWithExpression:(NSString *)expression
{
    XCDeclareWeakSelf(weakSelf);
    
    [self.searchService performSearchWithQuery:expression
                             completionHandler:^(NSArray *results) {
                                 [weakSelf updateSearchResults:results];
                                 [weakSelf resizeWindowToAccomodateSearchResults];
                             }];
}

@end
