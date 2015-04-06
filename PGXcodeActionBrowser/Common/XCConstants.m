//
//  XCConstants.m
//  XCActionBar
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCConstants.h"
#import "XCActionBar.h"

static NSCache *fontCache = nil;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
FOUNDATION_EXPORT NSFont *XCFontAwesomeWithSize(CGFloat size)
{
    static dispatch_once_t onceToken;
    static NSFontDescriptor *descriptor = nil;
    dispatch_once(&onceToken, ^{
        NSURL *fontURL           = [[NSBundle bundleForClass:[XCActionBar class]] URLForResource:@"fontawesome-webfont" withExtension:@"ttf"];
        NSArray *fontDescriptors = CFBridgingRelease(CTFontManagerCreateFontDescriptorsFromURL((CFURLRef)fontURL));
        fontCache = [[NSCache alloc] init];
        
        descriptor = fontDescriptors.firstObject;
    });

    NSString *key = [NSString stringWithFormat:@"fontawesome-%f", size];
    if([fontCache objectForKey:key] == nil) {
            [fontCache setObject:[NSFont fontWithDescriptor:descriptor size:size]
                          forKey:key];
    }
    return [fontCache objectForKey:key];
}
