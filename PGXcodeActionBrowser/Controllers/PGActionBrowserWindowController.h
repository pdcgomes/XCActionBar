//
//  PGActionBrowserWindowController.h
//  XCActionBar
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Cocoa/Cocoa.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol PGSearchService;
@protocol XCIDEContext;
@interface PGActionBrowserWindowController : NSWindowController

@property (nonatomic, weak) id<PGSearchService> searchService;
@property (nonatomic, weak) id<XCIDEContext   > context;

- (id)initWithBundle:(NSBundle *)bundle;

- (void)updateSearchResults:(NSArray *)results;
- (void)clearSearchResults;
- (void)executeLastAction;

@end
