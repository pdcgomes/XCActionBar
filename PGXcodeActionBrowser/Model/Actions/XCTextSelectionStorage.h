//
//  XCTextSelectionStorage.h
//  XCActionBar
//
//  Created by Pedro Gomes on 23/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCTextSelectionStorage <NSObject>

- (BOOL     )saveSelection:(NSArray *)selectionRanges withIdentifier:(NSString *)identifier;

- (NSArray *)loadSelectionWithIdentifier:(NSString *)identifier;

- (BOOL     )deleteSelectionWithIdentifier:(NSString *)identifier;
- (BOOL     )deleteAllSelections;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCTextSelectionStorage : NSObject <XCTextSelectionStorage>

@end
