//
//  XCActionBarSearchDataSource.h
//  XCActionBar
//
//  Created by Pedro Gomes on 09/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionBarDataSource.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCSearchService;
@protocol XCSearchMatchEntry;
@interface XCActionBarSearchDataSource : NSObject <XCActionBarDataSource>

@property (nonatomic, copy, readonly) NSString *searchQuery;

- (instancetype)initWithSearchService:(id<XCSearchService>)searchService;

- (void)updateSelectedObjectIndex:(NSUInteger)index;
- (void)updateSearchQuery:(NSString *)query;
- (void)clearSearchResults;

- (NSUInteger)numberOfResults;

- (id<XCSearchMatchEntry>)objectAtIndex:(NSUInteger)index;
- (id<XCSearchMatchEntry>)selectedObject;

@end
