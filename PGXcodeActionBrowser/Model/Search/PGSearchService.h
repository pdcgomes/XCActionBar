//
//  PGSearchService.h
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^PGSearchServiceCompletionHandler)(NSArray *results);

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol PGSearchService <NSObject>

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
@interface PGSearchService : NSObject <PGSearchService>

- (instancetype)initWithIndex:(id<PGActionIndex>)index;

@end
