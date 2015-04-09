//
//  XCActionBarPresetDataSource.h
//  XCActionBar
//
//  Created by Pedro Gomes on 09/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCActionPreset;
@protocol XCActionPresetSource;
@interface XCActionBarPresetDataSource : NSObject

- (void)updateWithPresetSource:(id<XCActionPresetSource>)presetSource;

- (void)updateSelectedObjectIndex:(NSUInteger)index;
- (void)clearResults;

- (NSUInteger)numberOfPresets;

- (id<XCActionPreset>)objectAtIndex:(NSUInteger)index;
- (id<XCActionPreset>)selectedObject;

@end
