//
//  PGUnitTestsActionProvider.m
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "IDETest.h"
#import "IDETestable-Protocol.h"
#import "IDETestManager.h"
#import "IDEWorkspace.h"

#import "PGBlockAction.h"
#import "PGWorkspaceUnitTestsActionProvider.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface PGWorkspaceUnitTestsActionProvider ()

@property (nonatomic,   weak) IDETestManager *testManager;
@property (nonatomic,   weak) IDEWorkspace *workspace;

@property (nonatomic, strong) NSArray *actions;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation PGWorkspaceUnitTestsActionProvider

@synthesize delegate;

#pragma mark - Dealloc and Initialization

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithWorkspace:(IDEWorkspace *)workspace
{
    if((self = [super init])) {
        self.workspace   = workspace;
        self.testManager = [workspace testManager];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)actionCategory
{
    return @"Unit Tests";
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)actionGroupName
{
    return @"Unit Tests";
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)findAllActions
{
    return [NSArray arrayWithArray:self.actions];
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
    RTVDeclareWeakSelf(weakSelf);
    
    dispatch_async(indexerQueue, ^{
        [weakSelf buildAvailableActions];
        if(completionHandler) completionHandler();
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)prepareActionsWithCompletionHandler:(PGGeneralCompletionHandler)completionHandler
{
    RTVDeclareWeakSelf(weakSelf);
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
    
    NSDictionary *testCasesByURL = [self.testManager testablesByFileURL];
    NSArray *testCaseURLs        = [testCasesByURL allKeys];

    for(NSURL *testCaseURL in testCaseURLs) {
        id<NSFastEnumeration> tests = [self.testManager testsForFileURL:testCaseURL];
        
        for(IDETest *test in tests) {
            
            PGBlockAction *action = [[PGBlockAction alloc] initWithTitle:test.identifier
                                                                subtitle:[(id<IDETestable>)test.testable name]
                                                                  action:^{
                                                                      TRLog(@"<RunUnitTestAction>, <test=%@>", test.identifier);
            }];
            [actions addObject:action];
            
            TRLog(@"<action:: title=%@, subtitle=%@, hint=%@>", action.title, action.subtitle, action.hint);

        }
    }
    self.actions = [NSArray arrayWithArray:actions];
}

@end
