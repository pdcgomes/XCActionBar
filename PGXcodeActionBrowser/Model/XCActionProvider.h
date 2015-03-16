//
//  PGActionBrowserProvider.h
//  XCActionBar
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGConstants.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCActionProvider;
@protocol XCActionProviderDelegate <NSObject>

- (void)actionProviderDidNotifyOfIndexRebuildNeeded:(id<XCActionProvider>)provider;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCActionProvider <NSObject>

@property (nonatomic, weak) id<XCActionProviderDelegate> delegate;

- (void)prepareActionsOnQueue:(dispatch_queue_t)indexerQueue
            completionHandler:(PGGeneralCompletionHandler)completionHandler;
- (void)prepareActionsWithCompletionHandler:(PGGeneralCompletionHandler)completionHandler;

- (NSString *)actionCategory;
- (NSString *)actionGroupName;

- (NSArray *)findAllActions;
- (NSArray *)findActionsMatchingExpression:(NSString *)expression;

@end
