//
//  XCCodeSnippetProvider.m
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 15/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCCodeSnippetProvider.h"

#import "XCBlockAction.h"

#import "XCIDEContext.h"
#import "XCSurroundWithSnippetAction.h"

#import "IDECodeSnippet.h"
#import "IDECodeSnippetRepository.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCCodeSnippetProvider ()

@property (nonatomic) NSArray *actions;
@property (nonatomic) IDECodeSnippetRepository *repository;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCCodeSnippetProvider : NSObject

@synthesize delegate;

#pragma mark - Dealloc and Initialization

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithCodeSnippetRepository:(IDECodeSnippetRepository *)repository
{
    if((self = [super init])) {
        self.repository = repository;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)actionCategory
{
    return @"Code Snippets";
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)actionGroupName
{
    return @"Code Snippets";
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)findAllActions
{
    return self.actions;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)findActionsMatchingExpression:(NSString *)expression
{
    return @[];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)prepareActionsOnQueue:(dispatch_queue_t)indexerQueue completionHandler:(PGGeneralCompletionHandler)completionHandler
{
    XCDeclareWeakSelf(weakSelf);
    
    dispatch_async(indexerQueue, ^{
        [weakSelf buildAvailableActions];
        if(completionHandler) completionHandler();
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)prepareActionsWithCompletionHandler:(PGGeneralCompletionHandler)completionHandler
{
    XCDeclareWeakSelf(weakSelf);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf buildAvailableActions];
        if(completionHandler) completionHandler();
    });
}

#pragma mark - Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)buildAvailableActions
{
    NSMutableArray *actions = [NSMutableArray array];

    for(IDECodeSnippet *snippet in self.repository.codeSnippets) @autoreleasepool {{
        XCLog(@"<CodeSnippet>, <id=%@, title=%@, shortcut=%@, scopes=%@>", snippet.identifier, snippet.title, snippet.completionPrefix, snippet.completionScopes);
        
        XCBlockAction *action = [[XCBlockAction alloc] initWithTitle:snippet.title
                                                            subtitle:snippet.summary
                                                                hint:snippet.completionPrefix
                                                              action:^(id<XCIDEContext> context) {
                                                                  [context.sourceCodeTextView insertText:snippet.contents];
                                                              }];
        action.enabled = YES;
        action.group   = [self actionGroupName];
        action.representedObject = snippet;
        
        [actions addObject:action];
        
        ////////////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////////////
        // Build "Surround With snippet actions"
        ////////////////////////////////////////////////////////////////////////////////
        if([XCSurroundWithSnippetAction checkSnippetCompatibility:snippet] == NO) continue;
        
        XCSurroundWithSnippetAction *surroundWithSnippetAction = [XCSurroundWithSnippetAction actionWithSnippet:snippet];
        [actions addObject:surroundWithSnippetAction];
    }}

    ////////////////////////////////////////////////////////////////////////////////
    // Build custom SurroundWithPasteboardSnippetAction
    ////////////////////////////////////////////////////////////////////////////////
    [actions addObject:[[XCSurroundWithTextSnippetAction alloc] initWithSpec:
                        @{XCSurroundWithActionIdentifierKey: @"SurroundWithPasteboardSnippetAction[%@]",
                          XCSurroundWithActionTitleKey:      @"Surround text with pasteboard snippet",
                          XCSurroundWithActionSummaryKey:    @"Surrounds selection with pasteboard \"Prefix <# token #> suffix\"",
                          XCSurroundWithActionPrefixKey:     @"",
                          XCSurroundWithActionSuffixKey:     @""}]];
    
    self.actions = [NSArray arrayWithArray:actions];
}

@end
