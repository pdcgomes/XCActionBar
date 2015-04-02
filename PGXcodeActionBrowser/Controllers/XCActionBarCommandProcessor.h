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
@protocol XCActionBarCommandProcessor <NSObject>

- (BOOL)enterActionSearchState;
- (BOOL)enterActionArgumentState;

- (BOOL)searchActionWithExpression:(NSString *)query;
- (BOOL)autoCompleteWithSelectedAction;
- (BOOL)cancel;

- (BOOL)selectNextSearchResult;
- (BOOL)selectPreviousSearchResult;

- (BOOL)executeSelectedAction;
- (BOOL)executeSelectedActionWithArguments:(NSArray *)arguments;

@end
