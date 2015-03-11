//
//  PGUtils.m
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "PGUtils.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *PGBuildModifierKeyMaskString(NSUInteger mask)
{
    NSDictionary *flagsToStrMap = @{@(NSShiftKeyMask):      @"\u21e7",
                                    @(NSControlKeyMask):    @"\u2303",
                                    @(NSCommandKeyMask):    @"\u2318",
                                    @(NSAlternateKeyMask):  @"\u2325"};
    if(TRCheckContainsKey(flagsToStrMap, @(mask)) == YES) {
        return flagsToStrMap[@(mask)];
    }
    return @"";
}
