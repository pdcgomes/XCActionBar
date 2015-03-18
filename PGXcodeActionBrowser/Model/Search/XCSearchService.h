//
//  PGSearchService.h
//  XCActionBar
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^PGSearchServiceCompletionHandler)(NSArray *results);

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCSearchService <NSObject>

// Will automatically interrupt other search operations
- (void)performSearchWithQuery:(NSString *)expression completionHandler:(PGSearchServiceCompletionHandler)completionHandler;

// Interrupts any inflight search operation
- (void)interruptSearches;

// Updates the internal search index data
- (void)updateIndex:(id)index;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol PGActionIndex;
@protocol XCSearchStrategy;
@interface XCSearchService : NSObject <XCSearchService>

- (instancetype)initWithIndex:(id<PGActionIndex>)index
                     strategy:(id<XCSearchStrategy>)strategy;

@end
