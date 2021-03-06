//
//  XCActionBarSearchStateInputHandler.m
//  XCActionBar
//
//  Created by Pedro Gomes on 29/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionInterface.h"
#import "XCActionBarSearchStateCommandHandler.h"
#import "XCActionBarCommandProcessor.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCActionBarSearchStateCommandHandler ()

@property (nonatomic, copy) NSString *searchExpression;

@property (nonatomic, weak) id<XCActionBarCommandProcessor> commandProcessor;
@property (nonatomic, weak) NSTextField *inputField;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCActionBarSearchStateCommandHandler

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithCommandProcessor:(id<XCActionBarCommandProcessor>)processor
{
    if((self = [super init])) {
        self.commandProcessor = processor;
    }
    return self;
}

#pragma mark - XCActionBarCommandHandler

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)enterWithInputControl:(NSTextField *)field
{
    self.inputField = field;
    
    id delegate = self.inputField.delegate;
    self.inputField.delegate = nil;
    
    self.inputField.stringValue       = (self.searchExpression ?: @"");
    self.inputField.placeholderString = @"Action ...";

    self.inputField.delegate = delegate;
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
    return [self.commandProcessor selectPreviousSearchResult];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)handleCursorDownCommand
{
    return [self.commandProcessor selectNextSearchResult];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)handleEnterCommand
{
    id<XCActionInterface> selectedAction = [self.commandProcessor retrieveSelectedAction];
    XCReturnFalseUnless(selectedAction != nil);
    
    return ([selectedAction requiresArguments] == NO ?
            [self.commandProcessor executeSelectedAction] :
            [self.commandProcessor enterActionArgumentState]);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)handleTabCommand
{
    id<XCActionInterface> selectedAction = [self.commandProcessor retrieveSelectedAction];
    XCReturnFalseUnless(selectedAction != nil);
    
    return ([selectedAction acceptsArguments] ?
            [self.commandProcessor enterActionArgumentState] :
            [self.commandProcessor autoCompleteWithSelectedAction]);
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
    self.searchExpression = text;
    
    return [self.commandProcessor searchActionWithExpression:text];
}

@end
