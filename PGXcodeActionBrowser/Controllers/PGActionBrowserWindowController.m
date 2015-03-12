//
//  PGActionBrowserWindowController.m
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "PGActionBrowserWindowController.h"
#import "PGSearchService.h"

#import "PGSearchResultCell.h"
//NSUpArrowFunctionKey        = 0xF700,
//NSDownArrowFunctionKey      = 0xF701,
//NSLeftArrowFunctionKey      = 0xF702,
//NSRightArrowFunctionKey     = 0xF703,

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface PGActionBrowserWindowController () <NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, NSWindowDelegate>

@property (nonatomic) NSRect frameForEmptySearchResults;

@property (nonatomic) NSDictionary *commandHandlers;

@property (weak) IBOutlet NSTextField *searchField;
@property (weak) IBOutlet NSTableView *searchResultsTable;

@property (nonatomic) NSArray *searchResults;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation PGActionBrowserWindowController

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)initWithBundle:(NSBundle *)bundle
{
    if((self = [super initWithWindowNibName:NSStringFromClass([PGActionBrowserWindowController class])])) {
        
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)windowDidLoad
{
    [super windowDidLoad];
    
    RTVDeclareWeakSelf(weakSelf);
    self.commandHandlers = @{NSStringFromSelector(@selector(moveUp:)):      [^{ [weakSelf selectNextSearchResult]; } copy],
                             NSStringFromSelector(@selector(moveDown:)):    [^{ [weakSelf selectPreviousSearchResult]; } copy]};
    
    self.searchField.focusRingType = NSFocusRingTypeNone;
    self.searchField.delegate      = self;
    self.searchField.nextResponder = self;
    
    self.searchResultsTable.rowSizeStyle            = NSTableViewRowSizeStyleMedium;
    self.searchResultsTable.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;

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
    TRLog(@"<KeyDown>, <event=%@>", theEvent);
    
    [super keyDown:theEvent];
}

#pragma mark - NSWindowDelegate

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)windowDidBecomeKey:(NSNotification *)notification
{
    self.frameForEmptySearchResults = self.window.frame;
    
    [self.window makeFirstResponder:self.searchField];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)windowDidResignKey:(NSNotification *)notification
{
    [self close];
    [self restoreWindowSize];
}

#pragma mark - NSTextDelegate

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)controlTextDidChange:(NSNotification *)notification
{
    NSTextField *textField = notification.object;

    TRLog(@"<SearchQueryChanged>, <query=%@>", textField.stringValue);

    // TODO: wait a bit before attempting to update search results - cancel previous update if any
    [self updateSearchResults:[textField.stringValue componentsSeparatedByCharactersInSet:[NSCharacterSet alphanumericCharacterSet]]];
    [self resizeWindowToAccomodateSearchResults];
    [self.searchService performSearchWithQuery:textField.stringValue
                             completionHandler:^(NSArray *results) {
        
    }];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
    TRLog(@"<doCommandBySelector>, <cmd=%@>", NSStringFromSelector(command));
    
    NSString *commandKey = NSStringFromSelector(command);
    BOOL handleCommand   = (TRCheckContainsKey(self.commandHandlers, commandKey) == YES);
    if(handleCommand == YES) {
        dispatch_block_t commandHandler = self.commandHandlers[commandKey];
        commandHandler();
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
    PGSearchResultCell *cell = [tableView makeViewWithIdentifier:NSStringFromClass([PGSearchResultCell class]) owner:self];
    [cell.textField setStringValue:[NSString stringWithFormat:@"Result #%@", @(row)]];
    
    return cell;
}

#pragma mark - Public Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)updateSearchResults:(NSArray *)results
{
    TRLog(@"<UpdatedSearchResults>, <results=%@>", results);
    
    self.searchResults = results;
    [self.searchResultsTable reloadData];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)clearSearchResults
{
    
}

#pragma mark - Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)selectNextSearchResult
{
    TRLog(@"<selectNextSearchResult>");
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)selectPreviousSearchResult
{
    TRLog(@"<selectPreviousSearchResult>");
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)resizeWindowToAccomodateSearchResults
{
    if(TRCheckIsEmpty(self.searchResults)) {
        [self.window setFrame:self.frameForEmptySearchResults display:NO];
    }
    else {
        NSRect resizedWindowFrame = (NSRect) {
            .origin = self.frameForEmptySearchResults.origin,
            .size   = NSMakeSize(self.frameForEmptySearchResults.size.width, self.frameForEmptySearchResults.size.height + 250.0),
        };
        [self.window setFrame:resizedWindowFrame
                      display:YES];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)restoreWindowSize
{
    [self.window setFrame:self.frameForEmptySearchResults
                  display:YES];
}

@end
