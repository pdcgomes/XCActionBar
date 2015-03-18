//
//  XCSearchStrategy.h
//  XCActionBar
//
//  Created by Pedro Gomes on 18/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCSearchStrategy <NSObject>

- (void)performSearchWithQuery:(NSString *)expression completionHandler:(PGSearchServiceCompletionHandler)completionHandler;

@end
