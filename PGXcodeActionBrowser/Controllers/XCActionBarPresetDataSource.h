//
//  XCActionBarPresetDataSource.h
//  XCActionBar
//
//  Created by Pedro Gomes on 09/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionBarDataSource.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCActionPreset;
@protocol XCActionPresetSource;
@interface XCActionBarPresetDataSource : NSObject <XCActionBarDataSource>

- (instancetype)initWithPresetSource:(id<XCActionPresetSource>)presetSource;

- (id<XCActionPreset>)objectAtIndex:(NSUInteger)index;
- (id<XCActionPreset>)selectedObject;

@end
