//
//  XCActionTemplateSource.h
//  XCActionBar
//
//  Created by Pedro Gomes on 09/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCActionPresetSource <NSObject>

@property (nonatomic, copy) NSString *presetSummary;

- (NSUInteger)numberOfPresets;
- (NSArray *)retrievePresets;

@end
