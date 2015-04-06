//
//  XCExpandTextSnippetAction.h
//  XCActionBar
//
//  Created by Pedro Gomes on 04/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCCustomAction.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@class IDECodeSnippet;
@interface XCExpandCodeSnippetAction : XCCustomAction

- (instancetype)initWithCodeSnippet:(IDECodeSnippet *)codeSnippet;

@end
