//
//  XCCodeSnippetProvider.h
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 15/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "PGActionBrowserProvider.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@class IDECodeSnippetRepository;
@interface XCCodeSnippetProvider : NSObject <PGActionProvider>

- (instancetype)initWithCodeSnippetRepository:(IDECodeSnippetRepository *)repository;

@end
