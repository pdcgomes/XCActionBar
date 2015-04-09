//
//  XCActionBrowserWindowController.h
//  XCActionBar
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Cocoa/Cocoa.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCSearchService;
@protocol XCIDEContext;
@interface XCActionBarWindowController : NSWindowController

@property (nonatomic, weak) id<XCSearchService> searchService;
@property (nonatomic, weak) id<XCIDEContext   > context;

- (id)initWithBundle:(NSBundle *)bundle searchService:(id<XCSearchService>)searchService;

- (void)updateSearchResults:(NSArray *)results;
- (void)clearSearchResults;
- (void)executeLastAction;

@end
