//
//  XCActionBarCommandProcessor.h
//  XCActionBar
//
//  Created by Pedro Gomes on 02/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCActionInterface;
@protocol XCActionPreset;
@protocol XCActionBarCommandProcessor <NSObject>

- (BOOL)enterActionSearchState;
- (BOOL)enterActionArgumentState;
- (BOOL)enterActionPresetState;

- (BOOL)searchActionWithExpression:(NSString *)query;
- (BOOL)autoCompleteWithSelectedAction;
- (BOOL)cancel;

- (BOOL)selectNextSearchResult;
- (BOOL)selectPreviousSearchResult;

- (BOOL)executeSelectedAction;
- (BOOL)executeSelectedActionWithArguments:(NSString *)arguments;
//- (BOOL)executeAction:(id)action;
//- (BOOL)executeAction:(id)action withArguments:(NSString *)arguments;
- (BOOL)executeActionPreset:(id<XCActionPreset>)preset;

// REVIEW: move to a separate protocol? this works for now
- (id<XCActionInterface>)retrieveSelectedAction;
- (id<XCActionPreset>)retrieveSelectedPreset;

@end
