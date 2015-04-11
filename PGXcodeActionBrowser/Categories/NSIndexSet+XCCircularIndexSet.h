//
//  NSIndexSet+XCCircularIndexSet.h
//  XCActionBar
//
//  Created by Pedro Gomes on 11/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface NSIndexSet (XCCircularIndexSet)

- (void)setSelectedIndex:(NSUInteger)index;
- (NSUInteger)selectedIndex;

- (NSUInteger)nextIndex;
- (NSUInteger)previousIndex;

- (void)selectNextIndex;
- (void)selectPreviousIndex;

@end
