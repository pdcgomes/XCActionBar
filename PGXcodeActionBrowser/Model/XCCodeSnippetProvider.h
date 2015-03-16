//
//  XCCodeSnippetProvider.h
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 15/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionProvider.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@class IDECodeSnippetRepository;
@interface XCCodeSnippetProvider : NSObject <XCActionProvider>

- (instancetype)initWithCodeSnippetRepository:(IDECodeSnippetRepository *)repository;

@end
