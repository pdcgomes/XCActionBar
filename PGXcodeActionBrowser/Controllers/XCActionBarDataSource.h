//
//  XCActionBarDataSource.h
//  XCActionBar
//
//  Created by Pedro Gomes on 10/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCActionPreset;
@protocol XCActionPresetSource;
@protocol XCActionBarDataSource <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic,   copy, readonly) NSString   *searchQuery;

- (void)updateSelectedObjectIndex:(NSUInteger)index;
- (void)updateSearchQuery:(NSString *)query;
- (void)clearResults;

- (NSUInteger)numberOfObjects;

- (id)objectAtIndex:(NSUInteger)index;
- (id)selectedObject;

@end
