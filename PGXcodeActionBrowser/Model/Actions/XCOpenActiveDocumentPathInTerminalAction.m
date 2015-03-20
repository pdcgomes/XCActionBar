//
//  XCOpenActiveDocumentPathInTerminalAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 20/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCOpenActiveDocumentPathInTerminalAction.h"

#import "PGUtils.h"
#import "XCIDEContext.h"
#import "XCIDEHelper.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCOpenActiveDocumentPathInTerminalAction ()

@property (nonatomic) NSArray *supportedApplicationList;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCOpenActiveDocumentPathInTerminalAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithPrioritizedTerminalApplicationList:(NSArray *)applicationList
{
    if((self = [super init])) {
        self.supportedApplicationList = applicationList;
        self.title    = @"Open in terminal";
        self.subtitle = @"Opens the active file's directory in the terminal application";
        self.enabled  = YES;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    if([context editorDocument] == nil) return NO;
    
    NSString *directoryPathName = [[[context editorDocument].fileURL path] stringByDeletingLastPathComponent];

    for(NSString *handlerAppName in self.supportedApplicationList) {
        @try {
            if([[NSWorkspace sharedWorkspace] openFile:directoryPathName withApplication:handlerAppName] == YES) {
                return YES;
            }
        }
        @catch(NSException *exception) {}
    }
    return NO;
}

@end
