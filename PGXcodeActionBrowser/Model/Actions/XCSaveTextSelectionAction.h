//
//  XCSaveSelectionAction.h
//  XCActionBar
//
//  Created by Pedro Gomes on 23/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCCustomAction.h"

FOUNDATION_EXPORT NSString *const XCTextSelectionMarkerAttributeName;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCTextSelectionStorage;
@interface XCTextSelectionAction : XCCustomAction

@property (nonatomic, readonly) id<XCTextSelectionStorage> textSelectionStorage;

- (instancetype)initWithTextSelectionStorage:(id<XCTextSelectionStorage>)textSelectionStorage;

- (void)undoAction:(NSDictionary *)info;
- (BOOL)validateSavedSelectionsInContext:(id<XCIDEContext>)context documentIdentifier:(NSString *)documentIdentifier;
- (NSArray *)validateAndLoadSavedSelectionsInContext:(id<XCIDEContext>)context documentIdentifier:(NSString *)documentIdentifier;
- (BOOL)recomputeAndSaveSelectionsInContext:(id<XCIDEContext>)context documentIdentifier:(NSString *)documentIdentifier;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCSaveTextSelectionAction : XCTextSelectionAction
@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCLoadTextSelectionAction : XCTextSelectionAction
@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCClearTextSelectionAction : XCTextSelectionAction
@end
