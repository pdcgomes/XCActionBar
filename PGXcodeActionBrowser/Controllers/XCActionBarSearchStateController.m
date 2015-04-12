//
//  XCActionBarSearchStateInputHandler.m
//  XCActionBar
//
//  Created by Pedro Gomes on 29/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCInputValidation.h"
#import "NSIndexSet+XCCircularIndexSet.h"

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

@property (nonatomic) NSIndexSet *dataIndexSet;

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
    [self selectSearchResultAtIndex:[self.dataIndexSet selectedIndex]];
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
    [self.dataIndexSet selectPreviousIndex];
    [self selectSearchResultAtIndex:[self.dataIndexSet selectedIndex]];
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)handleCursorDownCommand
{
    [self.dataIndexSet selectNextIndex];
    [self selectSearchResultAtIndex:[self.dataIndexSet selectedIndex]];
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)handleCursorLeftCommand
{
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)handleCursorRightCommand;
{
    [self handleTabCommand];
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)handleDoubleClickCommand
{
    return [self handleEnterCommand];
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
    [self resetDataIndexSet];
    
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

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)resetDataIndexSet
{
    self.dataIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.searchDataSource numberOfObjects])];
    [self.dataIndexSet setSelectedIndex:0];
}

@end
