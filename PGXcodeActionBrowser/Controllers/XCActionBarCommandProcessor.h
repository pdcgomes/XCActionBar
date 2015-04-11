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
- (BOOL)enterActionArgumentStateWithAction:(id<XCActionInterface>)action;
- (BOOL)enterActionPresetStateWithAction:(id<XCActionInterface>)action;

- (BOOL)cancel;
- (void)close;

- (BOOL)selectNextSearchResult;
- (BOOL)selectPreviousSearchResult;

- (BOOL)executeAction:(id<XCActionInterface>)action;
- (BOOL)executeAction:(id<XCActionInterface>)action withArguments:(NSString *)arguments;
//- (BOOL)executeAction:(id)action;
//- (BOOL)executeAction:(id)action withArguments:(NSString *)arguments;
- (BOOL)executeActionPreset:(id<XCActionPreset>)preset;

// REVIEW: move to a separate protocol? this works for now
//- (id<XCActionInterface>)retrieveSelectedAction;
- (id<XCActionPreset>)retrieveSelectedPreset;

- (void)resizeWindowToAccomodateSearchResults;

@end
