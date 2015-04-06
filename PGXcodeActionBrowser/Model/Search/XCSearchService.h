//
//  XCSearchService.h
//  XCActionBar
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCSearchStrategy.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCSearchService <NSObject>

// Will automatically interrupt other search operations
- (void)performSearchWithQuery:(NSString *)expression completionHandler:(XCSearchServiceCompletionHandler)completionHandler;

// Interrupts any inflight search operation
- (void)interruptSearches;

// Updates the internal search index data
- (void)updateIndex:(id)index;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCActionIndex;
@protocol XCSearchStrategy;
@interface XCSearchService : NSObject <XCSearchService>

- (instancetype)initWithIndex:(id<XCActionIndex>)index
                     strategy:(id<XCSearchStrategy>)strategy;

@end
