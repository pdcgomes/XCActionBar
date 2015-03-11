//
//  PGActionBrowserWindowController.h
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Cocoa/Cocoa.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface PGActionBrowserWindowController : NSWindowController

@property (nonatomic, weak) id searchService;

- (id)initWithBundle:(NSBundle *)bundle;

@end
