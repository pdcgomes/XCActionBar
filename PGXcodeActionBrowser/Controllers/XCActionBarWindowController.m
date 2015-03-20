//
//  XCActionBrowserWindowController.m
//  XCActionBar
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionBarWindowController.h"
#import "XCActionInterface.h"
#import "XCSearchService.h"

#import "XCSearchResultCell.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"

//NSUpArrowFunctionKey        = 0xF700,
//NSDownArrowFunctionKey      = 0xF701,
//NSLeftArrowFunctionKey      = 0xF702,
//NSRightArrowFunctionKey     = 0xF703,

typedef BOOL (^PGCommandHandler)(void);

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCActionBarWindowController () <NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, NSWindowDelegate>

@property (nonatomic) NSRect frameForEmptySearchResults;
@property (nonatomic) CGFloat searchFieldBottomConstraintConstant;

@property (nonatomic) NSDictionary *commandHandlers;

@property (weak) IBOutlet NSTextField *searchField;
@property (weak) IBOutlet NSTableView *searchResultsTable;
@property (weak) IBOutlet NSLayoutConstraint *searchFieldBottomConstraint;
@property (weak) IBOutlet NSLayoutConstraint *searchResultsTableHeightConstraint;
@property (weak) IBOutlet NSLayoutConstraint *searchResultsTableBottomConstraint;

@property (nonatomic) NSArray *searchResults;

@property (weak) id<XCActionInterface> lastExecutedAction;

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
    self.commandHandlers = @{
                             NSStringFromSelector(@selector(moveUp:)):       [^BOOL { return [weakSelf selectPreviousSearchResult]; } copy],
                             NSStringFromSelector(@selector(moveDown:)):     [^BOOL { return [weakSelf selectNextSearchResult]; } copy],
                             NSStringFromSelector(@selector(insertNewline:)):[^BOOL { return [weakSelf executeSelectedAction]; } copy],
                             NSStringFromSelector(@selector(insertTab:)):    [^BOOL { return [weakSelf autoCompleteWithSelectedAction]; } copy]
                             };
    
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
    [self executeSelectedAction];
}

#pragma mark - NSWindowDelegate

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)windowDidBecomeKey:(NSNotification *)notification
{
    self.searchFieldBottomConstraintConstant = self.searchFieldBottomConstraint.constant;
    self.frameForEmptySearchResults = self.window.frame;
    
    [self.window makeFirstResponder:self.searchField];
    
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

    // TODO: wait a bit before attempting to update search results - cancel previous update if any
    [self performSearchWithExpression:textField.stringValue];

}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
    XCLog(@"<doCommandBySelector>, <cmd=%@>", NSStringFromSelector(command));
    
    NSString *commandKey = NSStringFromSelector(command);
    BOOL handleCommand   = (TRCheckContainsKey(self.commandHandlers, commandKey) == YES);
    if(handleCommand == YES) {
        PGCommandHandler commandHandler = self.commandHandlers[commandKey];
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
    
    id<XCActionInterface> action = self.searchResults[row];
    
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:TRSafeString(action.title)];
    
    [title addAttribute:NSForegroundColorAttributeName
                  value:(action.enabled ? [NSColor blackColor] : [NSColor darkGrayColor])
                  range:NSMakeRange(0, title.length)];
    
    for(NSValue *rangeValue in action.searchQueryMatchRanges) {
        [title addAttributes:@{NSBackgroundColorAttributeName:[NSColor colorWithCalibratedRed:1.000 green:1.000 blue:0.519 alpha:0.250],
                               NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                               NSUnderlineColorAttributeName: [NSColor yellowColor]}
                       range:rangeValue.rangeValue];
    }
    
    cell.textField.allowsEditingTextAttributes = YES;
    
    cell.textField.attributedStringValue = title;
    cell.hintTextField.stringValue       = TRSafeString(action.hint);
    cell.subtitleTextField.stringValue   = TRSafeString(action.subtitle);
    
    return cell;
}

#pragma mark - Public Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)updateSearchResults:(NSArray *)results
{
    XCLog(@"<UpdatedSearchResults>, <results=%@>", results);
    
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
    [self.lastExecutedAction executeWithContext:self.context];
}

#pragma mark - Event Action Handlers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)selectNextSearchResult
{
    XCLog(@"<selectNextSearchResult>");
    
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
    XCLog(@"<selectPreviousSearchResult>");
    
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
    
    id<XCActionInterface> selectedAction = self.searchResults[selectedIndex];
    BOOL executed = [selectedAction executeWithContext:self.context];

    if(executed) {
        [self close];
        self.lastExecutedAction = selectedAction;
    }
    
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
