//
//  XCSurroundWithSnippetAction.h
//  XCActionBar
//
//  Created by Pedro Gomes on 18/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCSurroundWithAction.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@class IDECodeSnippet;
@interface XCSurroundWithSnippetAction : XCSurroundWithAction

// Checks whether the provided snippet can be used within a 'surround with' context
+ (BOOL)checkSnippetCompatibility:(IDECodeSnippet *)snippet;

+ (instancetype)actionWithSnippet:(IDECodeSnippet *)snippet;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCSurroundWithTextSnippetAction : XCSurroundWithAction

+ (BOOL)checkTextSnippetCompatibility:(NSString *)snippet;

- (instancetype)initWithSpec:(NSDictionary *)spec;

@end