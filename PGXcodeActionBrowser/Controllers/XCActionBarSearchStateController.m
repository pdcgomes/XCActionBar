//
//  XCActionBarSearchStateInputHandler.m
//  XCActionBar
//
//  Created by Pedro Gomes on 29/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCInputValidation.h"

#import "XCActionBarCommandProcessor.h"
#import "XCActionBarDataSource.h"
#import "XCActionBarSearchStateController.h"
#import "XCActionInterface.h"
#import "XCActionPresetSource.h"
#import "XCSearchMatchEntry.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCActionBarSearchStateController ()

@property (nonatomic, copy) NSString *searchExpression;

@property (nonatomic, weak) id<XCActionBarCommandProcessor> commandProcessor;
@property (nonatomic, weak) id<XCActionBarDataSource      > searchDataSource;

@property (nonatomic, weak) NSTableView *tableView;
@property (nonatomic, weak) NSTextField *inputField;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCActionBarSearchStateController

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithCommandProcessor:(id<XCActionBarCommandProcessor>)processor
                        searchDataSource:(id<XCActionBarDataSource>)searchDataSource
                               tableView:(NSTableView *)tableView
                              inputField:(NSTextField *)inputField
{
    if((self = [super init])) {
        self.commandProcessor = processor;
        self.searchDataSource = searchDataSource;
        self.inputField       = inputField;
        self.tableView        = tableView;
    }
    return self;
}

#pragma mark - XCActionBarCommandHandler

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)enter
{
    self.tableView.delegate   = self.searchDataSource;
    self.tableView.dataSource = self.searchDataSource;

    id delegate = self.inputField.delegate;
    self.inputField.delegate = nil;
    
    self.inputField.stringValue       = (self.searchExpression ?: @"");
    self.inputField.placeholderString = @"Action ...";

    self.inputField.delegate = delegate;
    
    XCReturnUnless(TRCheckIsEmpty(self.searchExpression) == NO);
    
    [self performSearchWithExpression:self.searchExpression];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)exit
{
    
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)handleCursorUpCommand
{
    NSInteger rowCount      = [self.tableView numberOfRows];
    NSInteger selectedIndex = self.tableView.selectedRow;
    NSInteger indexToSelect = (selectedIndex == -1 ? rowCount - 1 : (selectedIndex - 1 >= 0 ? selectedIndex - 1 : rowCount - 1));
    
    [self selectSearchResultAtIndex:indexToSelect];
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)handleCursorDownCommand
{
    NSInteger rowCount      = [self.tableView numberOfRows];
    NSInteger selectedIndex = self.tableView.selectedRow;
    NSInteger indexToSelect = (selectedIndex == -1 ? 0 : (selectedIndex + 1 < rowCount ? selectedIndex + 1 : 0));
    
    [self selectSearchResultAtIndex:indexToSelect];
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)handleDoubleClickCommand
{
    id<XCActionInterface> selectedAction = [self retrieveSelectedAction];
    XCReturnFalseUnless(selectedAction != nil);

    return [self.commandProcessor executeAction:selectedAction];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)handleEnterCommand
{
    id<XCActionInterface> selectedAction = [self retrieveSelectedAction];
    XCReturnFalseUnless(selectedAction != nil);
    
    return ([selectedAction requiresArguments] == NO ?
            [self.commandProcessor executeAction:selectedAction] :
            [self.commandProcessor enterActionArgumentStateWithAction:selectedAction]);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)handleTabCommand
{
    id<XCActionInterface> selectedAction = [self retrieveSelectedAction];
    XCReturnFalseUnless(selectedAction != nil);
    
    if([selectedAction conformsToProtocol:@protocol(XCActionPresetSource)]) {
        return [self.commandProcessor enterActionPresetStateWithAction:selectedAction];
    }
    
    return ([selectedAction acceptsArguments] ?
            [self.commandProcessor enterActionArgumentStateWithAction:selectedAction] :
            [self autoCompleteWithSelectedAction]);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)handleCancelCommand
{
    return [self.commandProcessor cancel];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)handleTextInputCommand:(NSString *)text
{
    [self performSearchWithExpression:text];
    
    return YES;
}

#pragma mark - Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)selectSearchResultAtIndex:(NSInteger)indexToSelect
{
    [self.searchDataSource updateSelectedObjectIndex:indexToSelect];
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:indexToSelect]
                byExtendingSelection:NO];
    [self.tableView scrollRowToVisible:indexToSelect];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)performSearchWithExpression:(NSString *)expression
{
    self.searchExpression = expression;
    
    [self.searchDataSource updateSearchQuery:expression];
    [self.tableView reloadData];
    
    [self.commandProcessor resizeWindowToAccomodateSearchResults];
    if(TRCheckIsEmpty(self.tableView) == NO) {
        [self selectSearchResultAtIndex:0];
        [self.searchDataSource updateSelectedObjectIndex:0];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)autoCompleteWithSelectedAction
{
    NSInteger selectedIndex = self.tableView.selectedRow;
    if(selectedIndex == -1) return YES;
    
    id<XCSearchMatchEntry> searchMatch = [self.searchDataSource objectAtIndex:selectedIndex];
    id<XCActionInterface> selectedAction = searchMatch.action;
    
    [self.inputField setStringValue:selectedAction.title];
    [self performSearchWithExpression:selectedAction.title];
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id<XCActionInterface>)retrieveSelectedAction
{
    id<XCSearchMatchEntry> searchMatch = [self.searchDataSource selectedObject];
    return (searchMatch ? searchMatch.action : nil);
}

@end
